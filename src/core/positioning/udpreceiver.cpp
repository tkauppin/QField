/***************************************************************************
 udpreceiver.cpp - UdpReceiver

 ---------------------
 begin                : December 2022
 copyright            : (C) 2022 by Mathieu Pellerin
 email                : mathieu@opengis.ch
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#include "udpreceiver.h"

#include <QFile>
#include <QMetaEnum>
#include <QSettings>

#if defined( Q_OS_ANDROID ) || defined( Q_OS_LINUX )
#include <sys/socket.h>
#endif

UdpReceiver::UdpReceiver( const QString &address, const int port, QObject *parent )
  : NmeaGnssReceiver( parent )
  , mAddress( address )
  , mPort( port )
  , mSocket( new QUdpSocket() )
  , mBuffer( new QBuffer() )
{
#if defined( Q_OS_ANDROID ) || defined( Q_OS_LINUX )
  int sockfd = socket( AF_INET, SOCK_DGRAM, 0 );
  int optval = 1;
  setsockopt( sockfd, SOL_SOCKET, SO_REUSEADDR,
              ( void * ) &optval, sizeof( optval ) );
  mSocket->setSocketDescriptor( sockfd, QUdpSocket::UnconnectedState );
#endif

  connect( mSocket, &QAbstractSocket::stateChanged, this, &UdpReceiver::setSocketState );
#if QT_VERSION < QT_VERSION_CHECK( 5, 15, 0 )
  connect( mSocket, qOverload<QAbstractSocket::SocketError>( &QAbstractSocket::error ), this, &UdpReceiver::handleError );
#else
  connect( mSocket, qOverload<QAbstractSocket::SocketError>( &QAbstractSocket::errorOccurred ), this, &UdpReceiver::handleError );
#endif

  connect( mSocket, &QUdpSocket::readyRead, this, [=]() {
    QByteArray datagram;
    while ( mSocket->hasPendingDatagrams() )
    {
      datagram.resize( int( mSocket->pendingDatagramSize() ) );
      mSocket->readDatagram( datagram.data(), datagram.size() );

      mBuffer->buffer().clear();
      mBuffer->seek( 0 );
      mBuffer->write( datagram );
      mBuffer->seek( 0 );
    }
  } );

  mReconnectTimer.setSingleShot( true );
  connect( &mReconnectTimer, &QTimer::timeout, this, [this]() {
    mSocket->connectToHost( mAddress, mPort, QUdpSocket::ReadOnly );
  } );

  setValid( !mAddress.isEmpty() && mPort > 0 );
  initNmeaConnection( mBuffer );
}

UdpReceiver::~UdpReceiver()
{
  disconnect( mSocket, &QAbstractSocket::stateChanged, this, &UdpReceiver::setSocketState );

  mSocket->deleteLater();
  mSocket = nullptr;
  mBuffer->deleteLater();
  mBuffer = nullptr;
}

void UdpReceiver::handleConnectDevice()
{
  if ( mAddress.isEmpty() || mPort == 0 )
  {
    return;
  }
  qInfo() << QStringLiteral( "UdpReceiver: Initiating connection to address %1 (port %2)" ).arg( mAddress, QString::number( mPort ) );
  mBuffer->open( QIODevice::ReadWrite );
  mSocket->bind( QHostAddress( mAddress ), mPort, QAbstractSocket::ShareAddress | QAbstractSocket::ReuseAddressHint );
  mSocket->joinMulticastGroup( QHostAddress( mAddress ) );
}

void UdpReceiver::handleDisconnectDevice()
{
  mReconnectOnDisconnect = false;
  mBuffer->close();
  mSocket->close();
}

void UdpReceiver::setSocketState( const QAbstractSocket::SocketState socketState )
{
  if ( mSocketState == socketState )
  {
    return;
  }

  switch ( socketState )
  {
    case QAbstractSocket::HostLookupState:
    case QAbstractSocket::ConnectingState:
    {
      mSocketStateString = tr( "Connecting…" );
      break;
    }
    case QAbstractSocket::ConnectedState:
    case QAbstractSocket::BoundState:
    {
      mReconnectOnDisconnect = true;
      mSocketStateString = tr( "Successfully connected" );
      break;
    }
    case QAbstractSocket::UnconnectedState:
    {
      mSocketStateString = tr( "Disconnected" );
      if ( mReconnectOnDisconnect )
      {
        mSocketStateString.append( QStringLiteral( ": %1" ).arg( mSocket->errorString() ) );
        mReconnectTimer.start( 2000 );
      }
      break;
    }
    default:
    {
      mSocketStateString = tr( "Socket state %1" ).arg( static_cast<int>( socketState ) );
    }
  }

  mSocketState = socketState;
  emit socketStateChanged( mSocketState );
  emit socketStateStringChanged( mSocketStateString );
}

void UdpReceiver::handleError( QAbstractSocket::SocketError error )
{
  switch ( error )
  {
    case QAbstractSocket::HostNotFoundError:
      mLastError = tr( "Could not find the remote host" );
      break;
    case QAbstractSocket::NetworkError:
      mLastError = tr( "Attempt to read or write from socket returned an error" );
      break;
    case QAbstractSocket::ConnectionRefusedError:
      mLastError = tr( "The connection was refused by the remote hose" );
      break;
    default:
      mLastError = tr( "UDP receiver error (%1)" ).arg( QMetaEnum::fromType<QAbstractSocket::SocketError>().valueToKey( error ) );
      break;
  }
  qInfo() << QStringLiteral( "UdpReceiver: Error: %1" ).arg( mLastError );

  emit lastErrorChanged( mLastError );
}
