import React from 'react';
import { Trash2 } from 'lucide-react';
import type { Event } from '../../types';

interface EventTableProps {
  events: Event[];
  onDelete: (token_id: string, timestamp: string) => void;
  isLoading?: boolean;
}

const EventTable: React.FC<EventTableProps> = ({
  events,
  onDelete,
  isLoading = false,
}) => {
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
      <div className="px-6 py-4 border-b border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Access Events</h3>
      </div>

      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Token ID
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Authorized
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Timestamp
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {events.map((event, index) => {
            // Safe access to event properties with fallbacks
            const tokenId = event?.token_id || '';
            const authorized = event?.authorized ?? false;
            const timestamp = event?.timestamp || '';
            
            // Create a unique key using available data
            const uniqueKey = `${tokenId}-${timestamp}-${index}`;
            
            return (
              <tr key={uniqueKey} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className="font-mono text-sm text-gray-900 bg-gray-100 px-2 py-1 rounded">
                    {tokenId || 'N/A'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                    authorized 
                      ? 'bg-green-100 text-green-800' 
                      : 'bg-red-100 text-red-800'
                  }`}>
                    {authorized ? 'Authorized' : 'Unauthorized'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">
                    {timestamp ? (
                      new Date(parseInt(timestamp)).toLocaleString()
                    ) : (
                      'N/A'
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    onClick={() => onDelete(tokenId, timestamp)}
                    disabled={!tokenId || !timestamp}
                    className="text-red-600 hover:text-red-900 p-1 rounded-md hover:bg-red-50 transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Delete Event"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      {events.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500">No events found for this token.</p>
        </div>
      )}
    </div>
  );
};

export default EventTable;