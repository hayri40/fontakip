import React, { useState, useEffect } from 'react';
import { Plus, Trash2, Edit3, FileText, Calendar, X, Check } from 'lucide-react';
import { StorageService } from '../../services/storage';
import { NoteItem } from '../../types';
import { AppFormatters } from '../../utils/formatters';

export const NotesTool: React.FC = () => {
  const [notes, setNotes] = useState<NoteItem[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingNote, setEditingNote] = useState<NoteItem | null>(null);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');

  const loadData = () => {
    setNotes(StorageService.getNotes());
  };

  useEffect(() => {
    loadData();
  }, []);

  const openForm = (note?: NoteItem) => {
    if (note) {
      setEditingNote(note);
      setTitle(note.title);
      setContent(note.content);
    } else {
      setEditingNote(null);
      setTitle('');
      setContent('');
    }
    setIsModalOpen(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;

    if (editingNote) {
      StorageService.updateNote(editingNote.id, title.trim(), content.trim());
    } else {
      StorageService.addNote(title.trim(), content.trim());
    }

    setIsModalOpen(false);
    loadData();
  };

  const handleDelete = (id: string) => {
    if (window.confirm('Bu notu silmek istediğinize emin misiniz?')) {
      StorageService.deleteNote(id);
      loadData();
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
          Yatırım Notları & Stratejilerim ({notes.length})
        </span>
        <button
          onClick={() => openForm()}
          className="px-3 py-1.5 bg-cyan-500 hover:bg-cyan-400 text-slate-950 font-bold text-xs rounded-xl transition flex items-center gap-1.5 shadow-md shadow-cyan-500/20"
        >
          <Plus className="w-3.5 h-3.5" /> Not Ekle
        </button>
      </div>

      {notes.length === 0 ? (
        <div className="p-8 text-center bg-[#141824] rounded-2xl border border-slate-800 text-slate-400 space-y-3">
          <FileText className="w-10 h-10 mx-auto text-slate-600" />
          <p className="text-sm">Henüz kayıtlı bir yatırım notu bulunmuyor.</p>
          <button
            onClick={() => openForm()}
            className="px-4 py-2 bg-cyan-500 text-slate-950 font-bold rounded-xl text-xs"
          >
            İlk Notunu Ekle
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {notes.map((note) => (
            <div
              key={note.id}
              className="p-5 rounded-2xl bg-[#141824] hover:bg-[#181E2E] border border-slate-800 transition flex flex-col justify-between space-y-3 group"
            >
              <div>
                <div className="flex items-start justify-between gap-2">
                  <h3 className="font-bold text-white text-base group-hover:text-cyan-400 transition">
                    {note.title}
                  </h3>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => openForm(note)}
                      className="p-1 text-slate-500 hover:text-slate-300 transition"
                      title="Düzenle"
                    >
                      <Edit3 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(note.id)}
                      className="p-1 text-slate-500 hover:text-red-400 transition"
                      title="Sil"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
                <div className="text-xs text-slate-500 flex items-center gap-1 mt-1">
                  <Calendar className="w-3.5 h-3.5" />
                  {AppFormatters.dateTime(note.createdAt)}
                </div>
                <p className="text-xs sm:text-sm text-slate-300 mt-3 whitespace-pre-wrap leading-relaxed">
                  {note.content}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Note Form Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
          <div className="bg-[#141824] border border-slate-700 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden">
            <div className="p-4 border-b border-slate-800 flex justify-between items-center bg-[#10131B]">
              <h3 className="font-bold text-white text-sm">
                {editingNote ? 'Notu Düzenle' : 'Yeni Not Ekle'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-white p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSave} className="p-5 space-y-4">
              <div>
                <label className="block text-xs text-slate-400 font-medium mb-1">Başlık</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Not başlığı..."
                  className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-cyan-500"
                  required
                />
              </div>

              <div>
                <label className="block text-xs text-slate-400 font-medium mb-1">İçerik</label>
                <textarea
                  rows={6}
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Yatırım teziniz, takip edilen hisseler veya hedefleriniz..."
                  className="w-full px-3.5 py-2.5 bg-[#10131B] border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-cyan-500 leading-relaxed"
                  required
                />
              </div>

              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 text-xs font-semibold hover:bg-slate-800 transition"
                >
                  İptal
                </button>
                <button
                  type="submit"
                  className="flex-1 py-2.5 rounded-xl bg-cyan-500 hover:bg-cyan-400 text-slate-950 text-xs font-bold transition shadow-md shadow-cyan-500/20"
                >
                  {editingNote ? 'Güncelle' : 'Kaydet'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
