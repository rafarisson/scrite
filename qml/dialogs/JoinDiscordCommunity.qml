/****************************************************************************
**
** Copyright (C) VCreate Logic Pvt. Ltd. Bengaluru
** Author: Prashanth N Udupa (prashanth@scrite.io)
**
** This code is distributed under GPL v3. Complete text of the license
** can be found here: https://www.gnu.org/licenses/gpl-3.0.txt
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

pragma Singleton

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

import io.scrite.components 1.0

import "qrc:/js/utils.js" as Utils
import "qrc:/qml/globals"
import "qrc:/qml/controls"
import "qrc:/qml/helpers"

DialogLauncher {
    id: root

    function launch(allowCloseAfter) { return doLaunch({"allowCloseAfter": allowCloseAfter ? allowCloseAfter : 0}) }

    readonly property url infoUrl: "https://www.scrite.io/index.php/forum/"
    readonly property url inviteUrl: "https://discord.gg/bGHquFX5jK"

    name: "JoinDiscordCommunity"
    singleInstanceOnly: true

    dialogComponent: VclDialog {
        id: dialog

        property int allowCloseAfter: 0

        title: "Join us on Discord"

        width: 640
        height: 550

        content: Item {
            ColumnLayout {
                anchors.centerIn: parent

                spacing: 20

                Image {
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignHCenter

                    source: "qrc:/images/scrite_discord_button.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }

                VclText {
                    Layout.preferredWidth: 450
                    Layout.alignment: Qt.AlignHCenter

                    wrapMode: Text.WordWrap
                    text: "Join our growing community of Scrite users on Discord. Interact with our team for <font color=\"" + Runtime.colors.accent.a700.background + "\"><b>support</b></font>, look for solutions to issues you may face, post <b>questions</b>, report <b>bugs</b>, request <u>features</u>, and provide <u>feedback</u>.<br/><br/>If you already have Discord installed, use the invite link below."
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    spacing: 20

                    VclText {
                        id: discordInviteLink
                        font.family: "Courier New"
                        font.pointSize: Runtime.idealFontMetrics.font.pointSize + 2
                        text: root.inviteUrl
                    }

                    ToolButton {
                        icon.source: "qrc:/icons/content/content_copy.png"
                        onClicked: {
                            if(Scrite.app.copyToClipboard(root.inviteUrl)) {
                                MessageBox.information("Copy Successful",
                                                       "The invite link was copied to clipboard",
                                                       () => { })
                            }
                        }
                    }
                }

                VclText {
                    Layout.preferredWidth: 450
                    Layout.alignment: Qt.AlignHCenter

                    text: "Please note: There is <b>no phone or email support</b> available for Scrite."
                    color: Runtime.colors.primary.c600.background
                    wrapMode: Text.WordWrap
                    font.pointSize: Runtime.idealFontMetrics.font.pointSize-2
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter

                    spacing: 20

                    VclButton {
                        text: "More Info"
                        onClicked: {
                            Qt.openUrlExternally(root.infoUrl)
                            if(dialog.titleBarCloseButtonVisible)
                                Qt.callLater(dialog.close)
                        }
                    }

                    VclButton {
                        text: "Open Discord"
                        onClicked: {
                            Qt.openUrlExternally(root.inviteUrl)
                            if(dialog.titleBarCloseButtonVisible)
                                Qt.callLater(dialog.close)
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            if(allowCloseAfter > 0) {
                titleBarCloseButtonVisible = false
                Utils.execLater(dialog, allowCloseAfter, () => {
                                    dialog.titleBarCloseButtonVisible = true
                                })
            }
        }
    }
}
