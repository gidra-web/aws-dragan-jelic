import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import { employeeService } from '../services/api';
import EmployeeTable from '../components/Employees/EmployeeTable';
import EmployeeForm from '../components/Employees/EmployeeForm';
import Modal from '../components/UI/Modal';
import LoadingSpinner from '../components/UI/LoadingSpinner';
import type { Employee, CreateEmployeeRequest } from '../types';

const Employees: React.FC = () => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState<Employee | null>(null);

  useEffect(() => {
    fetchEmployees();
  }, []);

  const fetchEmployees = async () => {
    try {
      setLoading(true);
      const data = await employeeService.getAll();
      setEmployees(data);
    } catch (error) {
      console.error('Error fetching employees:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (data: CreateEmployeeRequest) => {
    try {
      setSubmitting(true);
      await employeeService.create(data);
      // Refetch all employees to ensure consistency
      await fetchEmployees();
      setIsModalOpen(false);
    } catch (error) {
      console.error('Error creating employee:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleUpdate = async (data: CreateEmployeeRequest) => {
    if (!editingEmployee) return;

    try {
      setSubmitting(true);
      await employeeService.update({
        id: editingEmployee.id,
        ...data,
      });
      // Refetch all employees to ensure consistency
      await fetchEmployees();
      setIsModalOpen(false);
      setEditingEmployee(null);
    } catch (error) {
      console.error('Error updating employee:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (employee: Employee) => {
    if (confirm('Are you sure you want to delete this employee?')) {
      try {
        await employeeService.delete(employee.id);
        // Refetch all employees to ensure consistency
        await fetchEmployees();
      } catch (error) {
        console.error('Error deleting employee:', error);
      }
    }
  };

  const handleEdit = (employee: Employee) => {
    setEditingEmployee(employee);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingEmployee(null);
  };

  const handleOpenCreateModal = () => {
    setEditingEmployee(null);
    setIsModalOpen(true);
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Employees</h1>
            <p className="mt-2 text-gray-600">
              Manage your organization's employees
            </p>
          </div>
          <button
            onClick={handleOpenCreateModal}
            className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 transition-colors duration-200"
          >
            <Plus className="w-5 h-5 mr-2" />
            Add Employee
          </button>
        </div>
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <EmployeeTable
          employees={employees}
          onEdit={handleEdit}
          onDelete={handleDelete}
          isLoading={loading}
        />
      )}

      <Modal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        title={editingEmployee ? 'Edit Employee' : 'Create Employee'}
      >
        <EmployeeForm
          employee={editingEmployee || undefined}
          onSubmit={editingEmployee ? handleUpdate : handleCreate}
          onCancel={handleCloseModal}
          isLoading={submitting}
        />
      </Modal>
    </div>
  );
};

export default Employees;