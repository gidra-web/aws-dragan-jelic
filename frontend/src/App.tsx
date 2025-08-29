import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Authenticator } from '@aws-amplify/ui-react';
import { getCurrentUser } from 'aws-amplify/auth';
import Layout from './components/Layout/Layout';
import Employees from './pages/Employees';
import Tokens from './pages/Tokens';
import Events from './pages/Events';
import LoadingSpinner from './components/UI/LoadingSpinner';
import './config/amplify';
import '@aws-amplify/ui-react/styles.css';

function App() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    checkAuthState();
  }, []);

  const checkAuthState = async () => {
    try {
      const currentUser = await getCurrentUser();
      setUser(currentUser);
    } catch (error) {
      console.log('No authenticated user');
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <LoadingSpinner />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Authenticator
        signUpAttributes={['email']}
        socialProviders={[]}
        variation="modal"
        components={{
          Header() {
            return (
              <div className="text-center py-8">
                <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl mx-auto mb-4 flex items-center justify-center">
                  <span className="text-2xl font-bold text-white">AP</span>
                </div>
                <h1 className="text-2xl font-bold text-gray-900">Admin Panel</h1>
                <p className="text-gray-600 mt-2">Sign in to manage your organization</p>
              </div>
            );
          },
        }}
      >
        {(authProps) => {
          const { user } = authProps;
          
          return (
            <Router>
              <Routes>
                <Route path="/" element={<Layout user={user} />}>
                  <Route index element={<Navigate to="/employees" replace />} />
                  <Route path="employees" element={<Employees />} />
                  <Route path="tokens" element={<Tokens />} />
                  <Route path="events" element={<Events />} />
                </Route>
              </Routes>
            </Router>
          );
        }}
      </Authenticator>
    </div>
  );
}

export default App;