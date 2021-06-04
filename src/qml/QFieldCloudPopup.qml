import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12

import org.qfield 1.0
import Theme 1.0

Popup {
  id: popup
  padding: 0

  Page {
    anchors.fill: parent

    header: PageHeader {
      title: qsTr('QFieldCloud')

      showCancelButton: cloudProjectsModel.currentProjectData.Status !== QFieldCloudProjectsModel.Uploading
                        || cloudProjectsModel.currentProjectData.Status !== QFieldCloudProjectsModel.Downloading
      showApplyButton: false
      busyIndicatorState: cloudConnection.status === QFieldCloudConnection.Connecting
            || cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Uploading
            || cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Downloading
            ? 'on'
            : 'off'

      onFinished: {
        popup.close()
      }
    }

    ColumnLayout {
      visible: cloudProjectsModel.currentProjectId && cloudConnection.status !== QFieldCloudConnection.LoggedIn
      id: connectionSettings
      anchors.fill: parent
      spacing: 2

      ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 10
        height: parent.height
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: qfieldCloudLogin.width
        contentHeight: qfieldCloudLogin.childrenRect.height
        clip: true

        QFieldCloudLogin {
          id: qfieldCloudLogin
          width: parent.parent.width
        }
      }

      Item {
          Layout.fillHeight: true
          height: 15
      }
    }

    ColumnLayout {
      visible: !cloudProjectsModel.currentProjectId
      anchors.fill: parent
      anchors.margins: 20
      anchors.topMargin: 50
      spacing: 2

      Text {
        Layout.fillWidth: true
        font: Theme.defaultFont
        text: '<style>a, a:hover, a:visited { color:' + Theme.mainColor + '; }></style>' +
              qsTr('The current project is not stored on QFieldCloud.<br><br>') +
              qsTr('Storing projects on QFieldCloud offers seamless synchornization, offline editing, and team management.<br><br>') +
              ' <a href="https://qfield.cloud/">' + qsTr( 'Learn more about QFieldCloud' ) + '</a>.'
        textFormat: Text.RichText
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter

        onLinkActivated: Qt.openUrlExternally(link)
      }

      Item {
          Layout.fillHeight: true
          height: 15
      }
    }

    ScrollView {
      visible: cloudProjectsModel.currentProjectId && cloudConnection.status === QFieldCloudConnection.LoggedIn
      padding: 0
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: ScrollBar.AsNeeded
      contentWidth: mainGrid.width
      contentHeight: mainGrid.height
      anchors.fill: parent
      clip: true

      GridLayout {
        id: mainGrid
        width: parent.parent.width
        columns: 1
        columnSpacing: 2
        rowSpacing: 2

        RowLayout {
          Text {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              id: welcomeText
              padding: 10
              text: switch(cloudConnection.status) {
                    case 0: qsTr( 'Disconnected from the cloud.' ); break;
                    case 1: qsTr( 'Connecting to the cloud.' ); break;
                    case 2: qsTr( 'Greetings %1.' ).arg( cloudConnection.username ); break;
                  }
              wrapMode: Text.WordWrap
              font: Theme.tipFont
          }

          Rectangle {
            id: cloudAvatarRect
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.margins: 10
            width: 48
            height: 48
            radius: width/2
            border.color: Theme.mainColor
            border.width: 1
            clip: true

            Rectangle {
              id: cloudAvatarMask
              anchors.centerIn: parent
              width: 46
              height: 46
              radius: width/2
            }

            Image {
              id: cloudAvatar
              anchors.fill: parent
              anchors.margins: 2
              fillMode: Image.PreserveAspectFit
              smooth: true
              source: cloudConnection.avatarUrl !== ''
                      ? cloudConnection.avatarUrl
                      : 'qrc:/images/qfieldcloud_logo.svg'
              width: 48
              height: 48
              sourceSize.width: width * screen.devicePixelRatio
              sourceSize.height: height * screen.devicePixelRatio
              layer.enabled: true
              layer.effect: OpacityMask {
                  maskSource: cloudAvatarMask
              }
            }
          }
        }

        Text {
          id: statusText
          visible: cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Downloading ||
                   cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Uploading
          font: Theme.tipFont
          color: Theme.gray
          text: switch(cloudProjectsModel.currentProjectData.Status ) {
                  case QFieldCloudProjectsModel.Downloading:
                    switch ( cloudProjectsModel.currentProjectData.ExportStatus ) {
                      case QFieldCloudProjectsModel.ExportFinishedStatus:
                        return qsTr('Downloading %1%…').arg( parseInt(cloudProjectsModel.currentProjectData.DownloadProgress * 100) )
                      default:
                        return qsTr('QFieldCloud is preparing the latest data just for you. This might take some time, please hold tight…')
                    }
                  case QFieldCloudProjectsModel.Uploading:
                    switch ( cloudProjectsModel.currentProjectData.UploadDeltaStatus ) {
                      case QFieldCloudProjectsModel.DeltaFileLocalStatus:
                        return qsTr('Uploading %1%…').arg( parseInt(cloudProjectsModel.currentProjectData.UploadDeltaProgress * 100) );
                      default:
                        return qsTr('QFieldCloud is applying the latest uploaded changes. This might take some time, please hold tight…')
                    }
                  default: '';
                }

          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
          Layout.fillWidth: true
          Layout.margins: 10
        }

        Rectangle {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          Layout.margins: 10
          width: 64
          height: 64
          color: 'transparent'
          visible: cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Downloading ||
                   cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Uploading

          Image {
            id: statusIcon
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: switch(cloudProjectsModel.currentProjectData.Status ) {
                    case QFieldCloudProjectsModel.Downloading:
                      switch ( cloudProjectsModel.currentProjectData.ExportStatus ) {
                        case QFieldCloudProjectsModel.ExportFinishedStatus:
                          return Theme.getThemeVectorIcon('ic_cloud_download_24dp');
                        default:
                          return Theme.getThemeVectorIcon('ic_cloud_active_24dp');
                      }
                    case QFieldCloudProjectsModel.Uploading:
                      switch ( cloudProjectsModel.currentProjectData.UploadDeltaStatus ) {
                        case QFieldCloudProjectsModel.DeltaFileLocalStatus:
                          return Theme.getThemeVectorIcon('ic_cloud_upload_24dp');
                        default:
                          return Theme.getThemeVectorIcon('ic_cloud_active_24dp');
                      }
                    default: '';
                  }
            width: parent.width
            height: parent.height
            sourceSize.width: width * screen.devicePixelRatio
            sourceSize.height: height * screen.devicePixelRatio
            opacity: 1

            SequentialAnimation {
              OpacityAnimator {
                  from: 1
                  to: 0.2
                  duration: 2000
                  target: statusIcon
              }
              OpacityAnimator {
                  from: 0.2
                  to: 1
                  duration: 2000
                  target: statusIcon
              }
              running: true
              loops: Animation.Infinite
            }
          }
        }

        Text {
          id: transferErrorText
          visible: false
          font: Theme.defaultFont
          text: ''
          color: Theme.darkRed
          wrapMode: Text.WordWrap
          horizontalAlignment: Text.AlignHCenter
          Layout.fillWidth: true

          Connections {
            target: cloudProjectsModel

            function onPushFinished(projectId, hasError, errorString) {
              transferErrorText.visible = hasError && cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Idle;

              if (transferErrorText.visible)
                transferErrorText.text = errorString
            }

            function onProjectDownloaded(projectId, projectName, hasError, errorString) {
              const projectData = cloudProjectsModel.getProjectData(projectId)

              transferErrorText.visible = hasError && projectData.Status === QFieldCloudProjectsModel.Idle;

              if (transferErrorText.visible)
                transferErrorText.text = errorString

              if (projectData.ExportedLayerErrors.length !== 0)
              {
                cloudExportLayersFeedback.exportedLayersListViewModel = projectData.ExportedLayerErrors;
                cloudExportLayersFeedback.visible = true;
              }
            }

            function onDataChanged() {
              transferErrorText.visible = cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Idle;
            }
          }
        }

        GridLayout {
          Layout.margins: 10
          Layout.maximumWidth: 525
          Layout.alignment: Qt.AlignHCenter
          id: mainInnerGrid
          width: parent.width
          visible: cloudConnection.status === QFieldCloudConnection.LoggedIn &&
                   cloudProjectsModel.currentProjectData.Status === QFieldCloudProjectsModel.Idle
          columns: 1
          columnSpacing: parent.columnSpacing
          rowSpacing: parent.rowSpacing

          Text {
            property bool hasError: cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            property int changesCount: cloudProjectsModel.layerObserver.deltaFileWrapper.count
            id: changesText
            font: Theme.tipFont
            color: hasError ? Theme.errorColor : Theme.gray
            text: {
              if (!hasError) {
                return changesCount !== 0
                       ? qsTr('There is/are %n local change(s)','',changesCount)
                       : qsTr('There are no local changes');
              } else {
                return qsTr('The locally stored cloud project has been corrupted')
              }
            }
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 20
            Layout.fillWidth: true
          }

          QfButton {
            id: syncButton
            Layout.fillWidth: true
            font: Theme.defaultFont
            text: qsTr('Synchronize')
            visible: !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            enabled: !!(cloudProjectsModel.currentProjectData && cloudProjectsModel.currentProjectData.CanSync)
                     && !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            icon.source: Theme.getThemeIcon('ic_cloud_download_24dp')
            icon.color: 'white'

            onClicked: uploadProject(true)
          }

          Text {
            id: syncText
            font: Theme.tipFont
            color: Theme.gray
            visible: !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            text: qsTr('Synchronize the whole project with all modified features and download the freshly updated project with all the applied changes from QFieldCloud.')
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 20
            Layout.fillWidth: true
          }

          QfButton {
            id: pushButton
            Layout.fillWidth: true
            font: Theme.defaultFont
            text: qsTr('Push changes')
            visible: !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            enabled: !!(cloudProjectsModel.currentProjectData && cloudProjectsModel.currentProjectData.CanSync)
                     && cloudProjectsModel.layerObserver.deltaFileWrapper.count > 0 && !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            icon.source: Theme.getThemeIcon('ic_cloud_upload_24dp')
            icon.color: 'white'

            onClicked: uploadProject(false)
          }

          Text {
            id: pushText
            font: Theme.tipFont
            color: Theme.gray
            visible: !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            text: qsTr('Save internet bandwidth by only pushing the local features and pictures to the cloud, without updating the whole project.')
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 20
            Layout.fillWidth: true
          }

          QfButton {
            id: discardButton
            Layout.fillWidth: true
            font: Theme.defaultFont
            bgcolor: Theme.darkRed
            text: !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
                  ? qsTr('Revert local changes')
                  : qsTr('Reset project')
            enabled: cloudProjectsModel.layerObserver.deltaFileWrapper.count > 0 || cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
            icon.source: Theme.getThemeIcon('ic_undo_white_24dp')
            icon.color: 'white'

            onClicked: {
              if (!cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()) {
                revertDialog.open();
              } else {
                resetDialog.open();
              }
            }
          }

          Text {
            id: discardText
            font: Theme.tipFont
            color: Theme.gray
            text: !cloudProjectsModel.layerObserver.deltaFileWrapper.hasError()
                  ? qsTr('Revert all modified features in the local cloud layers. You cannot restore those changes.')
                  : qsTr('The local copy of this cloud project has been corrupted. Resetting the project will re-download the cloud version and will remove any local changes, make sure those were copied first if needed.\n\nWhile you can still view and use the project, it is strongly recommended to reset to avoid any accidental data loss as none of the changes made will be pushed back to the cloud.')
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.bottomMargin: 10
            Layout.fillWidth: true
          }

          Rectangle {
            color: Theme.lightGray
            height: 1
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 5
          }

          Text {
            id: lastExportPushText
            font: Theme.tipFont
            color: Theme.gray
            text: {
              var exportText = ''
              var dt = cloudProjectsModel.currentProjectData.LastLocalExport
              if (dt) {
                dt = new Date(dt)
                if (dt.toLocaleDateString() === new Date().toLocaleDateString())
                  exportText = qsTr( 'Last synchronized at ' ) + dt.toLocaleTimeString()
                else
                  exportText = qsTr( 'Last synchronized on ' ) + dt.toLocaleString()
              }

              var pushText = ''
              dt = cloudProjectsModel.currentProjectData.LastLocalPushDeltas

              if (dt) {
                dt = new Date(dt)
                if (dt.toLocaleDateString() === new Date().toLocaleDateString())
                  pushText = qsTr( 'Last changes pushed at ' ) + dt.toLocaleTimeString()
                else
                  pushText = qsTr( 'Last changes pushed on ' ) + dt.toLocaleString()
              } else {
                pushText = qsTr( 'No changes pushed yet' )
              }

              return exportText + '\n' + pushText
            }
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true

            MouseArea {
              anchors.fill: parent
              onClicked: {
                qfieldCloudDeltaHistory.model = cloudProjectsModel.currentProjectData.DeltaList
                qfieldCloudDeltaHistory.open()
              }
            }
          }

          Text {
            font: Theme.tipFont
            color: Theme.mainColor
            text: cloudProjectsModel.currentProjectData.UploadAttachmentsStatus === QFieldCloudProjectsModel.UploadAttachmentsInProgress
                  ? qsTr( "%n attachment(s) are currently being uploaded in the background.", "", parseInt(cloudProjectsModel.currentProjectData.UploadAttachmentsCount) )
                  : ''
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
          }
        }
      }
    }
  }

  Connections {
    target: cloudConnection

    function onStatusChanged() {
      if (cloudConnection.status === QFieldCloudConnection.Disconnected) {
        displayToast(qsTr('Logged out'))
      } else if (cloudConnection.status === QFieldCloudConnection.Connecting) {
        displayToast(qsTr('Connecting...'))
      } else if (cloudConnection.status === QFieldCloudConnection.LoggedIn) {
        displayToast(qsTr('Logged in'))
        if ( cloudProjectsModel.currentProjectId != '' )
          cloudProjectsModel.refreshProjectDeltaList(cloudProjectsModel.currentProjectId)
      }
    }
  }


  Dialog {
    id: revertDialog
    parent: mainWindow.contentItem

    property int selectedCount: 0
    property bool isDeleted: false

    visible: false
    modal: true

    x: ( mainWindow.width - width ) / 2
    y: ( mainWindow.height - height ) / 2

    title: qsTr( "Revert local changes" )
    Label {
      width: parent.width
      wrapMode: Text.WordWrap
      text: qsTr( "Should local changes be reverted?" )
    }

    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
      revertLocalChangesFromCurrentProject();
    }
    onRejected: {
      visible = false
      popup.focus = true;
    }
  }

  Dialog {
    id: resetDialog
    parent: mainWindow.contentItem

    property int selectedCount: 0
    property bool isDeleted: false

    visible: false
    modal: true

    x: ( mainWindow.width - width ) / 2
    y: ( mainWindow.height - height ) / 2

    title: qsTr( "Reset cloud project" )
    Label {
      width: parent.width
      wrapMode: Text.WordWrap
      text: qsTr( "Last warning, resetting the cloud project will erase any local changes, are you sure you want to go ahead?" )
    }

    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
      resetCurrentProject();
    }
    onRejected: {
      visible = false
      popup.focus = true;
    }
  }

  function show() {
    visible = !visible

    if ( cloudProjectsModel.currentProjectId && cloudConnection.hasToken && cloudConnection.status === QFieldCloudConnection.Disconnected )
      cloudConnection.login();
    else if ( cloudProjectsModel.currentProjectId != '' )
      cloudProjectsModel.refreshProjectDeltaList(cloudProjectsModel.currentProjectId)

    if ( cloudConnection.status === QFieldCloudConnection.Connectiong )
      displayToast(qsTr('Connecting cloud'))
  }

  function uploadProject(shouldDownloadUpdates) {
    if (cloudProjectsModel.currentProjectData && cloudProjectsModel.currentProjectData.CanSync) {
      cloudProjectsModel.uploadProject(cloudProjectsModel.currentProjectId, shouldDownloadUpdates)
      return
    }
  }

  function revertLocalChangesFromCurrentProject() {
    if (cloudProjectsModel.currentProjectData && cloudProjectsModel.currentProjectData.CanSync) {
      if ( cloudProjectsModel.revertLocalChangesFromCurrentProject(cloudProjectsModel.currentProjectId) )
        displayToast(qsTr('Local changes reverted'))
      else
        displayToast(qsTr('Failed to revert changes'), 'error')

      return
    }

    displayToast(qsTr('No changes to revert'))
  }

  function resetCurrentProject() {
    cloudProjectsModel.discardLocalChangesFromCurrentProject(cloudProjectsModel.currentProjectId)
    cloudProjectsModel.downloadProject(cloudProjectsModel.currentProjectId, true)
  }
}
