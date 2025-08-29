import React, { useState, useEffect } from 'react';
import { Edit2, Trash2, Copy } from 'lucide-react';
import { employeeService } from '../../services/api';
import type { Token, Employee } from '../../types';

interface TokenTableProps {
  tokens: Token[];
  onEdit: (token: Token) => void;
  onDelete: (id: string) => void;
  isLoading?: boolean;
}

const TokenTable: React.FC<TokenTableProps> = ({
  tokens,
  onEdit,
  onDelete,
  isLoading = false,
}) => {
  const [employees, setEmployees] = useState<Employee[]>([]);

  useEffect(() => {
    const fetchEmployees = async () => {
      try {
        const data = await employeeService.getAll();
        setEmployees(data);
      } catch (error) {
        console.error('Error fetching employees:', error);
      }
    };

    fetchEmployees();
  }, []);

  const getEmployeeName = (employeeId: string) => {
    if (!employeeId) return 'Unknown';
    
    const employee = employees.find(emp => emp?.id === employeeId);
    if (!employee) return 'Unknown';
    
    const firstName = employee.first_name || '';
    const lastName = employee.last_name || '';
    
    return firstName || lastName ? `${firstName} ${lastName}`.trim() : 'Unknown';
  };

  const copyToClipboard = (text: string) => {
    if (text) {
      navigator.clipboard.writeText(text);
    }
  };

  if (isLoading) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="animate-pulse">
          <div className="h-12 bg-gray-200 rounded-t-lg"></div>
          {[...Array(5)].map((_, i) => (
            <div key={i} className="h-16 bg-gray-100 border-t border-gray-200"></div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white shadow rounded-lg overflow-hidden">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Token ID
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Employee
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Issued At
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {tokens.map((token) => {
            // Safe access to token properties with fallbacks
            const tokenId = token?.id || '';
            const employeeId = token?.employee_id || '';
            const issuedAt = token?.issued_at;
            
            return (
              <tr key={token.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center space-x-2">
                    <span className="font-mono text-sm text-gray-900 bg-gray-100 px-2 py-1 rounded">
                      {tokenId}
                    </span>
                    {tokenId && (
                      <button
                        onClick={() => copyToClipboard(tokenId)}
                        className="text-gray-400 hover:text-gray-600 transition-colors duration-200"
                        title="Copy token ID"
                      >
                        <Copy className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">
                    {getEmployeeName(employeeId)}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-500">
                    {issuedAt
                      ? new Date(issuedAt).toLocaleDateString()
                      : 'N/A'}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div className="flex justify-end space-x-2">
                    <button
                      onClick={() => onEdit(token)}
                      className="text-blue-600 hover:text-blue-900 p-1 rounded-md hover:bg-blue-50 transition-colors duration-200"
                      title="Edit Token"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => onDelete(token.id)}
                      className="text-red-600 hover:text-red-900 p-1 rounded-md hover:bg-red-50 transition-colors duration-200"
                      title="Delete Token"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      {tokens.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500">No tokens found.</p>
        </div>
      )}
    </div>
  );
};

export default TokenTable;