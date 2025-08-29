
import React, { useState, useEffect, useMemo } from 'react';
import { tokenService, eventService } from '../services/api';
import EventTable from '../components/Events/EventTable';
import LoadingSpinner from '../components/UI/LoadingSpinner';
import type { Token, Event } from '../types';

const Events: React.FC = () => {
  const [tokens, setTokens] = useState<Token[]>([]);
  const [allEvents, setAllEvents] = useState<Event[]>([]);
  const [selectedToken, setSelectedToken] = useState<string>('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Fetches all required data in parallel when the component first loads
    const fetchAllData = async () => {
      try {
        setLoading(true);
        const [tokensData, eventsData] = await Promise.all([
          tokenService.getAll(),
          eventService.getAll(),
        ]);
        setTokens(tokensData);
        setAllEvents(eventsData);
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchAllData();
  }, []);

  // useMemo efficiently recalculates the filtered list only when the source data changes
  const filteredEvents = useMemo(() => {
    if (!selectedToken) {
      return [];
    }
    // Filter all events to find ones that match the selected token
    const sorted = allEvents
      .filter(event => event.token_id === selectedToken)
      .sort((a, b) => Number(b.timestamp) - Number(a.timestamp)); // Sort by newest first
    return sorted;
  }, [selectedToken, allEvents]);


  const handleDeleteEvent = async (eventId: string) => {
    if (confirm('Are you sure you want to delete this event?')) {
      try {
        await eventService.delete(eventId);
        // Refetch all events to ensure the UI is consistent
        const updatedEvents = await eventService.getAll();
        setAllEvents(updatedEvents);
      } catch (error) {
        console.error('Error deleting event:', error);
      }
    }
  };

  return (
    <div className="p-8">
      <div className="mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Access Events</h1>
          <p className="mt-2 text-gray-600">
            View token access events and authorization status
          </p>
        </div>
      </div>

      {loading ? (
        <LoadingSpinner />
      ) : (
        <div className="space-y-6">
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Select Token</h3>
            <div className="max-w-md">
              <select
                value={selectedToken}
                onChange={(e) => setSelectedToken(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="" disabled>Choose a token...</option>
                {tokens.map((token) => (
                  <option key={token.id} value={token.id}>
                    {token.id}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {selectedToken && (
            <EventTable
              events={filteredEvents}
              onDelete={handleDeleteEvent}
              isLoading={false} // The main page loading is already handled
            />
          )}

          {!selectedToken && tokens.length > 0 && (
            <div className="bg-white shadow rounded-lg p-12 text-center">
              <div className="text-gray-500">
                <div className="w-16 h-16 bg-gray-100 rounded-full mx-auto mb-4 flex items-center justify-center">
                  <span className="text-2xl">📋</span>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Token Selected</h3>
                <p>Please select a token from the dropdown above to view its access events.</p>
              </div>
            </div>
          )}

          {tokens.length === 0 && !loading && (
            <div className="bg-white shadow rounded-lg p-12 text-center">
              <div className="text-gray-500">
                <div className="w-16 h-16 bg-gray-100 rounded-full mx-auto mb-4 flex items-center justify-center">
                  <span className="text-2xl">🎫</span>
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Tokens Available</h3>
                <p>Create some tokens first to start viewing access events.</p>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Events;
