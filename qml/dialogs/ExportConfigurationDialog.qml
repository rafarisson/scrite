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

Item {
    id: root

    parent: Scrite.window.contentItem

    function launch(exporter) {
        if(_private.dialogComponent.status !== Component.Ready) {
            Scrite.app.log("ExportConfigurationDialog is not ready!")
            return null
        }

        if(!exporter) {
            Scrite.app.log("No exporter supplied.")
            return null
        }

        var args = {
            exporter: null
        }

        if(typeof exporter === "string")
            args.exporter = Scrite.document.createExporter(exporter)
        else if(Scrite.app.verifyType(exporter, "AbstractExporter"))
            args.exporter = exporter
        else {
            Scrite.app.log("No exporter supplied.")
            return null
        }

        var dlg = _private.dialogComponent.createObject(root, args)
        if(dlg) {
            dlg.closed.connect(dlg.destroy)
            dlg.open()
            return dlg
        }

        Scrite.app.log("Couldn't launch ExportConfigurationDialog")
        return null
    }

    QtObject {
        id: _private

        property Component dialogComponent: Qt.createComponent("./exportconfigurationdialog/impl_ExportConfigurationDialog.qml", Component.PreferSynchronous, root)
    }
}
