import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import { tokenService } from '../services/api';
import TokenTable from '../components/Tokens/TokenTable';
import TokenForm from '../components/Tokens/TokenForm';
import Modal from '../components/UI/Modal';
import LoadingSpinner from '../components/UI/LoadingSpinner';
import type { Token, CreateTokenRequest } from '../types';

const Tokens: React.FC = () => {
  const [tokens, setTokens] = useState<Token[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingToken, setEditingToken] = useState<Token | null>(null);

  useEffect(() => {
    fetchTokens();
  }, []);

  const fetchTokens = async () => {
    try {
      setLoading(true);
      const data = await tokenService.getAll();
      setTokens(data);
    } catch (error) {
      console.error('Error fetching tokens:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (data: CreateTokenRequest) => {
    try {
      setSubmitting(true);
      await tokenService.create(data);
      // Refetch all tokens to ensure consistency
      await fetchTokens();
      setIsModalOpen(false);
    } catch (error) {
      console.error('Error creating token:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleUpdate = async (token: Token) => {
    try {
      setSubmitting(true);
      await tokenService.update(token);
      // Refetch all tokens to ensure consistency
      await fetchTokens();
      setIsModalOpen(false);
      setEditingToken(null);
    } catch (error) {
      console.error('Error updating token:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this token?')) {
      try {
        await tokenService.delete(id);
        // Refetch all tokens to ensure consistency
        await fetchTokens();
      } catch (error) {
        console.error('Error deleting token:', error);
      }
    }
  };

  const handleEdit = (token: Token) => {
    setEditingToken(token);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingToken(null);
  };

  const handleOpenCreateModal = () => {
    setEditingToken(null);
    setIsModalOpen(true);
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Tokens</h1>
            <p className="mt-2 text-gray-600">
              Manage access tokens for employees
            </p>
          </div>
          <button
            onClick={handleOpenCreateModal}
            className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 transition-colors duration-200"
          >
            <Plus className="w-5 h-5 mr-2" />
            Create Token
          </button>
        </div>
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <TokenTable
          tokens={tokens}
          onEdit={handleEdit}
          onDelete={handleDelete}
          isLoading={loading}
        />
      )}

      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title={editingToken ? 'Edit Token' : 'Create Token'}
      >
        {editingToken ? (
          <div className="space-y-4">
            <p className="text-gray-600">
              Token editing is not supported in this version.
            </p>
            <div className="flex justify-end">
              <button
                onClick={handleCloseModal}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:ring-2 focus:ring-gray-500 transition-colors duration-200"
              >
                Close
              </button>
            </div>
          </div>
        ) : (
          <TokenForm
            onSubmit={handleCreate}
            onCancel={handleCloseModal}
            isLoading={submitting}
          />
        )}
      </Modal>
    </div>
  );
};

export default Tokens;