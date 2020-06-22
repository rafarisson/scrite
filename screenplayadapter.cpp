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

#include "screenplay.h"
#include "garbagecollector.h"
#include "screenplayadapter.h"
#include "scritedocument.h"

ScreenplayAdapter::ScreenplayAdapter(QObject *parent)
    : QIdentityProxyModel(parent)
{
    connect(this, &ScreenplayAdapter::modelReset, this, &ScreenplayAdapter::updateCurrentIndexAndCount);
    connect(this, &ScreenplayAdapter::rowsRemoved, this, &ScreenplayAdapter::updateCurrentIndexAndCount);
    connect(this, &ScreenplayAdapter::rowsInserted, this, &ScreenplayAdapter::updateCurrentIndexAndCount);

    connect(this, &ScreenplayAdapter::modelAboutToBeReset, this, &ScreenplayAdapter::clearCurrentIndex);
    connect(this, &ScreenplayAdapter::rowsAboutToBeRemoved, this, &ScreenplayAdapter::clearCurrentIndex);
    connect(this, &ScreenplayAdapter::rowsAboutToBeInserted, this, &ScreenplayAdapter::clearCurrentIndex);
}

ScreenplayAdapter::~ScreenplayAdapter()
{

}

void ScreenplayAdapter::setSource(QObject *val)
{
    if(m_source == val)
        return;

    if(this->sourceModel() != nullptr)
    {
        Screenplay *screenplay = qobject_cast<Screenplay*>(this->sourceModel());
        if(screenplay->parent() == this)
            GarbageCollector::instance()->add(screenplay);
        else
        {
            disconnect(this, &ScreenplayAdapter::currentIndexChanged, screenplay, &Screenplay::setCurrentElementIndex);
            disconnect(screenplay, &Screenplay::currentElementIndexChanged, this, &ScreenplayAdapter::setCurrentIndex);
            disconnect(screenplay, &Screenplay::hasNonStandardScenesChanged, this, &ScreenplayAdapter::hasNonStandardScenesChanged);
        }
    }

    this->setCurrentIndex(-1);

    m_source = val;

    if(m_source != nullptr)
    {
        Screenplay *screenplay = qobject_cast<Screenplay*>(m_source);
        if(screenplay != nullptr)
        {
            this->setSourceModel(screenplay);

            connect(this, &ScreenplayAdapter::currentIndexChanged, screenplay, &Screenplay::setCurrentElementIndex);
            connect(screenplay, &Screenplay::currentElementIndexChanged, this, &ScreenplayAdapter::setCurrentIndex);
            connect(screenplay, &Screenplay::hasNonStandardScenesChanged, this, &ScreenplayAdapter::hasNonStandardScenesChanged);
        }
        else
        {
            Scene *scene = qobject_cast<Scene*>(m_source);
            if(scene != nullptr)
            {
                Screenplay *masterScreenplay = ScriteDocument::instance()->screenplay();

                screenplay = new Screenplay(this);
                if(masterScreenplay != nullptr)
                {
                    screenplay->setTitle(masterScreenplay->title());
                    screenplay->setSubtitle(masterScreenplay->subtitle());
                    screenplay->setAuthor(masterScreenplay->author());
                    screenplay->setVersion(masterScreenplay->version());
                }

                ScreenplayElement *element = new ScreenplayElement(screenplay);
                element->setScene(scene);
                screenplay->addElement(element);

                connect(screenplay, &Screenplay::hasNonStandardScenesChanged, this, &ScreenplayAdapter::hasNonStandardScenesChanged);

                this->setSourceModel(screenplay);
            }
            else
                this->setSourceModel(nullptr);
        }
    }
    else
        this->setSourceModel(nullptr);

    emit sourceChanged();

    if(this->isSourceScreenplay())
        this->setCurrentIndex(this->screenplay()->currentElementIndex());
}

bool ScreenplayAdapter::isSourceScene() const
{
    return qobject_cast<Scene*>(m_source) != nullptr;
}

bool ScreenplayAdapter::isSourceScreenplay() const
{
    return qobject_cast<Screenplay*>(m_source) != nullptr;
}

Screenplay *ScreenplayAdapter::screenplay() const
{
    return qobject_cast<Screenplay*>(this->sourceModel());
}

void ScreenplayAdapter::setCurrentIndex(int val)
{
    this->setCurrentIndexInternal(val);
    emit currentIndexChanged(m_currentIndex);
}

Scene *ScreenplayAdapter::currentScene() const
{
    return m_currentElement == nullptr ? nullptr : m_currentElement->scene();
}

bool ScreenplayAdapter::hasNonStandardScenes() const
{
    Screenplay *screenplay = this->screenplay();
    if(screenplay != nullptr)
        return screenplay->hasNonStandardScenes();

    return false;
}

ScreenplayElement *ScreenplayAdapter::splitElement(ScreenplayElement *ptr, SceneElement *element, int textPosition)
{
    Screenplay *screenplay = qobject_cast<Screenplay*>(m_source);
    if(screenplay != nullptr)
        return screenplay->splitElement(ptr, element, textPosition);

    return nullptr;
}

int ScreenplayAdapter::previousSceneElementIndex()
{
    Screenplay *screenplay = qobject_cast<Screenplay*>(m_source);
    if(screenplay != nullptr)
        return screenplay->previousSceneElementIndex();

    return 0;
}

int ScreenplayAdapter::nextSceneElementIndex()
{
    Screenplay *screenplay = qobject_cast<Screenplay*>(m_source);
    if(screenplay != nullptr)
        return screenplay->nextSceneElementIndex();

    return 0;
}

QVariant ScreenplayAdapter::at(int row) const
{
    const QModelIndex index = this->index(row, 0);
    if(index.isValid())
        return this->data(index, ModelDataRole);

    return QVariant();
}

QHash<int, QByteArray> ScreenplayAdapter::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if(roles.isEmpty())
    {
        roles[IdRole] = "id";
        roles[ScreenplayElementRole] = "screenplayElement";
        roles[ScreenplayElementTypeRole] = "screenplayElementType";
        roles[BreakTypeRole] = "breakType";
        roles[SceneRole] = "scene";
        roles[ModelDataRole] = "modelData";
        roles[RowNumberRole] = "rowNumber";
    }
    return roles;
}

QVariant ScreenplayAdapter::data(const QModelIndex &index, int role) const
{
    if(!index.isValid() || this->sourceModel() == nullptr)
        return QVariant();

    const QModelIndex srcIndex = this->mapToSource(index);
    const QVariant srcData = this->sourceModel()->data(srcIndex, Screenplay::ScreenplayElementRole);
    ScreenplayElement *element = srcData.value<ScreenplayElement*>();
    return this->data(element, index.row(), role);
}

void ScreenplayAdapter::setCurrentIndexInternal(int val)
{
    const int nrRows = this->rowCount();
    val = nrRows > 0 ? qBound(-1, val, nrRows-1) : -1;
    if(m_currentIndex == val)
        return;

    m_currentIndex = val;

    if(m_currentIndex >= 0)
    {
        const QModelIndex index = this->index(m_currentIndex, 0);
        ScreenplayElement *element = this->data(index, ScreenplayElementRole).value<ScreenplayElement*>();
        this->setCurrentElement(element);
    }
    else
        this->setCurrentElement(nullptr);
}

void ScreenplayAdapter::setCurrentElement(ScreenplayElement *val)
{
    if(m_currentElement == val)
        return;

    m_currentElement = val;
    emit currentElementChanged();
}

QVariant ScreenplayAdapter::data(ScreenplayElement *element, int row, int role) const
{
    if(element == nullptr)
        return QVariant();

    switch(role)
    {
    case IdRole:
        return element->sceneID();
    case ScreenplayElementRole:
        return QVariant::fromValue<ScreenplayElement*>(element);
    case ScreenplayElementTypeRole:
        return element->elementType();
    case BreakTypeRole:
        return element->breakType();
    case SceneRole:
        return QVariant::fromValue<Scene*>(element->scene());
    case RowNumberRole:
        return row;
    case ModelDataRole: {
            QVariantMap ret;
            const QHash<int, QByteArray> roles = this->roleNames();
            QHash<int, QByteArray>::const_iterator it = roles.begin();
            QHash<int, QByteArray>::const_iterator end = roles.end();
            while(it != end) {
                if(it.key() != ModelDataRole)
                    ret[ QString::fromLatin1(it.value()) ] = this->data(element, row, it.key());
                ++it;
            }
            return ret;
        }
    default:
        break;
    }

    return QVariant();
}

void ScreenplayAdapter::clearCurrentIndex()
{
    this->setCurrentIndexInternal(-1);
}

void ScreenplayAdapter::updateCurrentIndexAndCount()
{
    Screenplay *sp = this->screenplay();
    if(sp != nullptr)
        this->setCurrentIndexInternal(sp->currentElementIndex());

    emit elementCountChanged();
}
