/****************************************************************************
**
** Copyright (C) TERIFLIX Entertainment Spaces Pvt. Ltd. Bengaluru
** Author: Prashanth N Udupa (prashanth.udupa@teriflix.com)
**
** This code is distributed under GPL v3. Complete text of the license
** can be found here: https://www.gnu.org/licenses/gpl-3.0.txt
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

#include "form.h"
#include "networkaccessmanager.h"

#include <QDir>
#include <QUuid>
#include <QApplication>
#include <QJsonDocument>
#include <QNetworkReply>

FormQuestion::FormQuestion(QObject *parent)
    : QObject(parent)
{

}

FormQuestion::~FormQuestion()
{
    emit aboutToDelete(this);
}

void FormQuestion::setId(const QString &val)
{
    if(m_id == val || !m_id.isEmpty())
        return;

    m_id = val;
    emit idChanged();
}

void FormQuestion::setNumber(int val)
{
    if(m_number == val || val >= 0)
        return;

    m_number = val;
    emit numberChanged();
}

void FormQuestion::setQuestionText(const QString &val)
{
    if(m_questionText == val || !m_questionText.isEmpty())
        return;

    m_questionText = val;
    emit questionTextChanged();
}

void FormQuestion::setAnswerHint(const QString &val)
{
    if(m_answerHint == val || !m_answerHint.isEmpty())
        return;

    m_answerHint = val;
    emit answerHintChanged();
}

///////////////////////////////////////////////////////////////////////////////

Form::Form(QObject *parent)
    :QObject(parent)
{

}

Form::~Form()
{
    emit aboutToDelete(this);
}

QString Form::createdBy() const
{
    return m_createdBy.isEmpty() ? QStringLiteral("Scrite Project") : m_createdBy;
}

QString Form::version() const
{
    return m_version.isEmpty() ? QStringLiteral("1.0") : m_version;
}

QUrl Form::moreInfoUrl() const
{
    return m_moreInfoUrl.isEmpty() ? QUrl( QStringLiteral("https://www.scrite.io") ) : m_moreInfoUrl;
}

ObjectListPropertyModel<FormQuestion *> *Form::questionsModel() const
{
    return const_cast< ObjectListPropertyModel<FormQuestion*> *>(&m_questions);
}

FormQuestion *Form::questionAt(int index) const
{
    return m_questions.at(index);
}

QJsonObject Form::formDataTemplate() const
{
    const QList<FormQuestion*> list = m_questions.list();
    if(!m_formDataTemplate.isEmpty() || list.isEmpty())
        return m_formDataTemplate;

    QJsonObject ret;
    for(FormQuestion *q : list)
        ret.insert( q->id(), QString() );

    (const_cast<Form*>(this))->m_formDataTemplate = ret;
    return m_formDataTemplate;
}

void Form::validateFormData(QJsonObject &val)
{
    QJsonObject validated = this->formDataTemplate();
    QJsonObject::iterator it = validated.begin();
    QJsonObject::iterator end = validated.end();
    while(it != end)
    {
        it.value() = val.value( it.key() );
        ++it;
    }

    val = validated;
}

void Form::serializeToJson(QJsonObject &json) const
{
    // Since all properties in Form are read-only, we cannot expect QObjectSerializer
    // to serialize this class for us. That's the reason why we are explicitly
    // serializing the Form here.
    json.insert( QStringLiteral("id"), m_id );
    json.insert( QStringLiteral("type"), this->typeAsString() );
    json.insert( QStringLiteral("title"), m_title );
    json.insert( QStringLiteral("subtitle"), m_subtitle );
    json.insert( QStringLiteral("createdBy"), m_createdBy );
    json.insert( QStringLiteral("version"), m_version );
    json.insert( QStringLiteral("moreInfoUrl"), m_moreInfoUrl.toString() );

    const QList<FormQuestion*> list = m_questions.list();

    QJsonArray qArray;
    for(FormQuestion *q : list)
    {
        QJsonObject qjs;
        qjs.insert( QStringLiteral("id"), q->id() );
        qjs.insert( QStringLiteral("question"), q->questionText() );
        qjs.insert( QStringLiteral("answerHint"), q->answerHint() );
        qArray.append(qjs);
    }

    json.insert( QStringLiteral("questions"), qArray );
}

void Form::deserializeFromJson(const QJsonObject &json)
{
    // Since all properties in Form are read-only, we cannot expect QObjectSerializer
    // to serialize this class for us. That's the reason why we are explicitly
    // serializing the Form here.
    const QString idAttr = QStringLiteral("id");

    if(json.contains(idAttr))
        this->setId( json.value(idAttr).toString() );
    else
        this->setId( QUuid::createUuid().toString() );

    this->setTypeFromString( json.value(QStringLiteral("type")).toString() );
    this->setTitle( json.value(QStringLiteral("title")).toString() );
    this->setSubtitle( json.value(QStringLiteral("subtitle")).toString() );
    this->setCreatedBy( json.value(QStringLiteral("createdBy")).toString() );
    this->setVersion( json.value(QStringLiteral("version")).toString() );
    this->setMoreInfoUrl( QUrl(json.value(QStringLiteral("moreInfoUrl")).toString()) );

    QList<FormQuestion*> list;

    const QJsonArray qArray = json.value( QStringLiteral("questions") ).toArray();
    for(const QJsonValue &qjsi : qArray)
    {
        const QJsonObject qjs = qjsi.toObject();
        FormQuestion *question = new FormQuestion(this);
        connect(question, &FormQuestion::aboutToDelete, &m_questions, &ObjectListPropertyModel<FormQuestion*>::objectDestroyed);

        if(qjs.contains(idAttr))
            question->setId( qjs.value(idAttr).toString() );
        else
            question->setId( QUuid::createUuid().toString() );

        question->setNumber( list.size()+1 );
        question->setQuestionText( qjs.value(QStringLiteral("question")).toString() );
        question->setAnswerHint( qjs.value(QStringLiteral("answerHint")).toString() );
        list.append(question);
    }

    m_questions.assign(list);
}

void Form::setType(Type val)
{
    if(m_type == val)
        return;

    m_type = val;
    emit typeChanged();
}

void Form::setId(const QString &val)
{
    if(m_id == val || !m_id.isEmpty())
        return;

    m_id = val;
    emit idChanged();
}

void Form::setTitle(const QString &val)
{
    if(m_title == val || !m_title.isEmpty())
        return;

    m_title = val;
    emit titleChanged();
}

void Form::setSubtitle(const QString &val)
{
    if(m_subtitle == val || !m_subtitle.isEmpty())
        return;

    m_subtitle = val;
    emit subtitleChanged();
}

void Form::setCreatedBy(const QString &val)
{
    if(m_createdBy == val || !m_createdBy.isEmpty())
        return;

    m_createdBy = val;
    emit createdByChanged();
}

void Form::setVersion(const QString &val)
{
    if(m_version == val || !m_version.isEmpty())
        return;

    m_version = val;
    emit versionChanged();
}

void Form::setMoreInfoUrl(const QUrl &val)
{
    if(m_moreInfoUrl == val || !m_moreInfoUrl.isEmpty())
        return;

    m_moreInfoUrl = val;
    emit moreInfoUrlChanged();
}

void Form::setTypeFromString(const QString &val)
{
    static const int enumIndex = Form::staticMetaObject.indexOfEnumerator("Type");
    static const QMetaEnum enumerator = Form::staticMetaObject.enumerator(enumIndex);

    bool ok = true;
    const int itype = enumerator.keyToValue( qPrintable(val), &ok );
    if(!ok)
        this->setType(GeneralForm);
    else
        this->setType( Type(itype) );
}

QString Form::typeAsString() const
{
    static const int enumIndex = Form::staticMetaObject.indexOfEnumerator("Type");
    static const QMetaEnum enumerator = Form::staticMetaObject.enumerator(enumIndex);
    return QString::fromLatin1( enumerator.valueToKey(m_type) );
}

///////////////////////////////////////////////////////////////////////////////

Forms *Forms::global()
{
    static Forms *forms = new Forms(true, qApp);
    return forms;
}

Forms::Forms(QObject *parent)
      :ObjectListPropertyModel<Form*>(parent)
{
    connect(this, &ObjectListPropertyModel<Form*>::objectCountChanged,
            this, &Forms::formCountChanged);
}

Forms::Forms(bool, QObject *parent)
      :ObjectListPropertyModel<Form*>(parent)
{
    this->downloadForms();
}

Forms::~Forms()
{

}

Form *Forms::findForm(const QString &id) const
{
    if(id.isEmpty())
        return nullptr;

    const QList<Form*> forms = this->list();
    for(Form *form : forms)
    {
        if(form->id() == id)
            return form;
    }

    return nullptr;
}

QList<Form *> Forms::forms(Form::Type type) const
{
    const QList<Form*> forms = this->list();
    QList<Form*> ret;
    for(Form *form : forms)
    {
        if(form->type() == type)
            ret << form;
    }

    return ret;
}

Form *Forms::addForm(const QJsonObject &val)
{
    m_errorReport->clear();

    if(val.isEmpty())
    {
        m_errorReport->setErrorMessage( QStringLiteral("Cannot load form from empty JSON data.") );
        return nullptr;
    }

    Form *form = new Form(this);
    if( QObjectSerializer::fromJson(val, form) )
    {
        this->append(form);
        return form;
    }

    m_errorReport->setErrorMessage( QStringLiteral("Couldnt load form from JSON data.") );
    delete form;
    return nullptr;
}

Form *Forms::addFormFromFile(const QString &path)
{
    m_errorReport->clear();

    if( !QFile::exists(path) )
    {
        m_errorReport->setErrorMessage( QStringLiteral("File '%1' does not exist.").arg(path) );
        return nullptr;
    }

    QFile file(path);
    if( !file.open(QFile::ReadOnly) )
    {
        m_errorReport->setErrorMessage( QStringLiteral("Couldn't load '%1' for reading.").arg(path) );
        return nullptr;
    }

    QJsonParseError error;
    const QJsonDocument jsonDoc = QJsonDocument::fromJson(file.readAll(), &error);
    if(error.error != QJsonParseError::NoError)
    {
        m_errorReport->setErrorMessage( error.errorString() );
        return nullptr;
    }

    const QJsonObject jsonObj = jsonDoc.object();
    return this->addForm(jsonObj);
}

QList<Form*> Forms::addFormsInFolder(const QString &dirPath)
{
    m_errorReport->clear();

    QList<Form*> ret;
    const QDir dir(dirPath);
    const QFileInfoList fiList = dir.entryInfoList({QStringLiteral("*.sform")}, QDir::Files, QDir::Name);

    if(fiList.isEmpty())
        return ret;

    ErrorReport *actualErrorReport = m_errorReport;
    QStringList errors;

    for(const QFileInfo &fi : fiList)
    {
        ErrorReport tempErrorReport;
        m_errorReport = &tempErrorReport;

        Form *form = this->addFormFromFile(fi.absoluteFilePath());

        if(form)
            ret << form;
        else
        {
            const QString error = fi.fileName() + QStringLiteral(": ") + tempErrorReport.errorMessage();
            errors << error;
        }
    }

    m_errorReport = actualErrorReport;

    if(!errors.isEmpty())
        m_errorReport->setErrorMessage( errors.join(QStringLiteral(", ")) );

    return ret;
}

void Forms::serializeToJson(QJsonObject &json) const
{
    const QList<Form*> forms = this->list();

    QJsonArray data;

    for(Form *form : forms)
    {
        const QJsonObject formObj = QObjectSerializer::toJson(form);
        data.append(formObj);
    }

    json.insert( QStringLiteral("#data"), data );
}

void Forms::deserializeFromJson(const QJsonObject &json)
{
    const QJsonArray data = json.value( QStringLiteral("#data") ).toArray();
    QList<Form*> forms;

    for(const QJsonValue &item : data)
    {
        const QJsonObject formObj = item.toObject();
        Form *form = new Form(this);
        if( QObjectSerializer::fromJson(formObj, form) )
        {
            forms << form;
            continue;
        }

        delete form;
    }

    this->assign(forms);
}

void Forms::itemInsertEvent(Form *ptr)
{
    if(ptr)
        connect(ptr, &Form::aboutToDelete, this, &Forms::objectDestroyed);
}

void Forms::itemRemoveEvent(Form *ptr)
{
    if(ptr)
        disconnect(ptr, &Form::aboutToDelete, this, &Forms::objectDestroyed);
}

void Forms::downloadForms()
{
    if( this->findChild<QNetworkReply*>() != nullptr )
        return;

    const QUrl url = QUrl( QStringLiteral("http://www.teriflix.in/scrite/library/forms/forms.hexdb") );

    QNetworkAccessManager *nam = NetworkAccessManager::instance();
    QNetworkRequest request(url);
    QNetworkReply *reply = nam->get(request);
    reply->setParent(this);
    connect(reply, &QNetworkReply::finished, this, [=]() {
        const QByteArray bytes = reply->readAll();
        reply->deleteLater();

        const QByteArray bson = qUncompress(QByteArray::fromHex(bytes));

        const QJsonDocument doc = QJsonDocument::fromBinaryData(bson);
        if(doc.isNull())
            return;

        QJsonArray records;
        if(doc.isArray())
            records = doc.array();
        else
            records.append(doc.object());

        ErrorReport *actualErrorReport = m_errorReport;
        QStringList errors;

        QList<Form*> forms = this->list();

        for(const QJsonValue &record : qAsConst(records)) {
            ErrorReport tempErrorReport;
            m_errorReport = &tempErrorReport;

            const QJsonObject formJson = record.toObject();

            Form *form = new Form(this);
            if(QObjectSerializer::fromJson(formJson, form))
                forms.append(form);
            else {
                errors << tempErrorReport.errorMessage();
                delete form;
            }
        }

        this->assign(forms);

        m_errorReport = actualErrorReport;

        if(!errors.isEmpty())
            m_errorReport->setErrorMessage( errors.join(QStringLiteral(", ")) );
    });
}

