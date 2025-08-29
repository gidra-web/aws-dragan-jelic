import React, { useState, useEffect } from 'react';
import { employeeService } from '../../services/api';
import type { Employee, CreateTokenRequest } from '../../types';

interface TokenFormProps {
  onSubmit: (data: CreateTokenRequest) => void;
  onCancel: () => void;
  isLoading?: boolean;
}

const TokenForm: React.FC<TokenFormProps> = ({
  onSubmit,
  onCancel,
  isLoading = false,
}) => {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [selectedEmployeeId, setSelectedEmployeeId] = useState('');
  const [loadingEmployees, setLoadingEmployees] = useState(true);

  useEffect(() => {
    const fetchEmployees = async () => {
      try {
        const data = await employeeService.getAll();
        setEmployees(data);
      } catch (error) {
        console.error('Error fetching employees:', error);
      } finally {
        setLoadingEmployees(false);
      }
    };

    fetchEmployees();
  }, []);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedEmployeeId) {
      onSubmit({ employee_id: selectedEmployeeId });
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Select Employee
        </label>
        {loadingEmployees ? (
          <div className="w-full px-3 py-2 border border-gray-300 rounded-md bg-gray-50">
            Loading employees...
          </div>
        ) : (
          <select
            value={selectedEmployeeId}
            onChange={(e) => setSelectedEmployeeId(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            required
          >
            <option value="">Choose an employee</option>
            {employees.map((employee) => (
              <option key={employee.id} value={employee.id}>
                {employee.first_name} {employee.last_name} ({employee.email})
              </option>
            ))}
          </select>
        )}
      </div>

      <div className="flex justify-end space-x-3 pt-4">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:ring-2 focus:ring-gray-500 transition-colors duration-200"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={isLoading || !selectedEmployeeId}
          className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
        >
          {isLoading ? 'Creating...' : 'Create Token'}
        </button>
      </div>
    </form>
  );
};

export default TokenForm;