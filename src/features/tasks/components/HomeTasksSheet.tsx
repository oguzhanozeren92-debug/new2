import { useEffect, useRef } from 'react';
import { Check, ChevronRight, ListTodo, RefreshCw, X } from 'lucide-react';
import { createPortal } from 'react-dom';
import { useFieldTasks } from '../hooks/useFieldTasks';
import type { FieldTask } from '../services/fieldTasks.service';
import './HomeTasksSheet.css';

type Props = {
  open: boolean;
  fieldId: string;
  fieldName: string;
  onClose: () => void;
  onAction: (task: FieldTask) => void;
};

function sourceLabel(source: string) {
  if (source === 'field-readiness') return 'PUSULA GÖREVİ';
  if (source === 'model-readiness') return 'MODEL HAZIRLIĞI';
  if (source === 'pusula') return 'PUSULA';
  return 'GÖREV';
}

function priorityLabel(priority: number) {
  if (priority >= 90) return 'ÖNCELİKLİ';
  if (priority >= 70) return 'ÖNEMLİ';
  return null;
}

function isPhotoCheckTask(task: FieldTask) {
  const haystack = `${task.title} ${task.description ?? ''} ${task.actionTarget ?? ''}`
    .toLocaleLowerCase('tr-TR');

  return (
    haystack.includes('kontrol et') &&
    (
      haystack.includes('bölüm') ||
      haystack.includes('pusula önerisini') ||
      haystack.includes('gelişim') ||
      haystack.includes('nem') ||
      haystack.includes('drenaj') ||
      haystack.includes('drain') ||
      haystack.includes('observation') ||
      haystack.includes('photo')
    )
  );
}

function taskTitle(task: FieldTask) {
  if (!isPhotoCheckTask(task)) return task.title;
  if (task.title.toLocaleLowerCase('tr-TR').includes('fotoğraf yükle')) return task.title;
  return task.title.replace(/kontrol et/i, 'kontrol et ve fotoğraf yükle');
}

function actionLabel(task: FieldTask) {
  return isPhotoCheckTask(task) ? 'Kontrol et ve fotoğraf yükle' : 'Göreve git';
}

export default function HomeTasksSheet({
  open,
  fieldId,
  fieldName,
  onClose,
  onAction,
}: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const { tasks, loading, error, message, refresh, complete } = useFieldTasks(fieldId, open);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (open && !dialog?.open) dialog?.showModal();
    if (!open && dialog?.open) dialog.close();
  }, [open]);

  const close = () => {
    dialogRef.current?.close();
    onClose();
  };

  return createPortal(
    <dialog
      ref={dialogRef}
      className="tp-home-tasks-sheet"
      aria-label="Görevlerim"
      onCancel={(event) => {
        event.preventDefault();
        close();
      }}
      onClick={(event) => {
        if (event.target === event.currentTarget) close();
      }}
    >
      <div className="tp-home-tasks-handle" aria-hidden="true" />

      <header className="tp-home-tasks-head">
        <span className="tp-home-tasks-head-icon" aria-hidden="true">
          <ListTodo size={20} />
        </span>

        <div>
          <small>{fieldName || 'Tarlan'}</small>
          <h2>Görevlerim</h2>
        </div>

        <span className="tp-home-tasks-count">{tasks.length}</span>

        <button type="button" className="tp-home-tasks-close" onClick={close} aria-label="Kapat">
          <X size={20} />
        </button>
      </header>

      <div className="tp-home-tasks-intro">
        <p>Pusula, eksik tarla bilgilerine ve model ihtiyaçlarına göre sana tamamlanabilir görevler verir.</p>
        <button type="button" onClick={() => void refresh()} disabled={loading}>
          <RefreshCw size={15} className={loading ? 'is-spinning' : ''} />
          Yenile
        </button>
      </div>

      {message ? <p className="tp-home-tasks-message">{message}</p> : null}
      {error ? <p className="tp-home-tasks-error">{error}</p> : null}

      <div className="tp-home-tasks-list">
        {loading && !tasks.length ? (
          <div className="tp-home-tasks-empty">Görevlerin hazırlanıyor…</div>
        ) : tasks.length ? (
          tasks.map((task) => {
            const priority = priorityLabel(task.priority);

            return (
              <article className="tp-home-task-card" key={task.id}>
                <div className="tp-home-task-topline">
                  <span>{sourceLabel(task.source)}</span>
                  <div>
                    {priority ? <b>{priority}</b> : null}
                    {task.rewardPoints > 0 ? <em>+{task.rewardPoints} P</em> : null}
                  </div>
                </div>

                {isPhotoCheckTask(task) ? (
                  <div className="tp-home-task-photo-hint" aria-hidden="true">
                    Fotoğraf yükle
                  </div>
                ) : null}

                <h3>{taskTitle(task)}</h3>
                {task.description ? <p>{task.description}</p> : null}

                <div className="tp-home-task-actions">
                  {task.actionTarget ? (
                    <button
                      type="button"
                      className={`tp-home-task-open ${isPhotoCheckTask(task) ? 'is-photo-action' : ''}`}
                      onClick={() => {
                        close();
                        onAction(task);
                      }}
                    >
                      {actionLabel(task)}
                      <ChevronRight size={16} />
                    </button>
                  ) : (
                    <button
                      type="button"
                      className="tp-home-task-complete"
                      onClick={() => void complete(task)}
                    >
                      <Check size={15} />
                      Tamamlandı
                    </button>
                  )}
                </div>
              </article>
            );
          })
        ) : (
          <div className="tp-home-tasks-empty">
            <Check size={24} />
            <strong>Şimdilik görev yok</strong>
            <span>Pusula yeni bir ihtiyaç tespit ettiğinde görev burada görünecek.</span>
          </div>
        )}
      </div>
    </dialog>,
    document.body,
  );
}
