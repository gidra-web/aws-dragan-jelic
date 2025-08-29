import { get, post, put, del } from 'aws-amplify/api';
import { fetchAuthSession } from 'aws-amplify/auth';
import type { 
  Employee, 
  Token, 
  Event, 
  CreateEmployeeRequest, 
  UpdateEmployeeRequest,
  DeleteEmployeeRequest,
  CreateTokenRequest,
  UpdateTokenRequest,
  DeleteTokenRequest,
  DeleteEventRequest,
  CreateEventRequest 
} from '../types';

const API_NAME = 'admin-api';

// Helper function to get auth headers
const getAuthHeaders = async () => {
  try {
    const session = await fetchAuthSession();
    const idToken = session.tokens?.idToken?.toString();
    
    if (!idToken) {
      throw new Error('No ID token available');
    }
    
    return {
      'Authorization': `Bearer ${idToken}`,
      'Content-Type': 'application/json',
    };
  } catch (error) {
    console.error('Error getting auth session:', error);
    throw error;
  }
};

// Employee API
export const employeeService = {
  async getAll(): Promise<Employee[]> {
    try {
      console.log('Fetching employees...');
      const headers = await getAuthHeaders();
      console.log('Request headers:', headers);
      
      const response = await get({
        apiName: API_NAME,
        path: '/employee',
        options: {
          headers
        }
      }).response;
      
      console.log('Response received');
      const data = await response.body.json();
      console.log('Employees data:', data);
      return data as Employee[];
    } catch (error) {
      console.error('Error fetching employees:', error);
      throw error;
    }
  },

  async create(employee: CreateEmployeeRequest): Promise<Employee> {
    try {
      const headers = await getAuthHeaders();
      const response = await post({
        apiName: API_NAME,
        path: '/employee',
        options: {
          headers,
          body: employee
        }
      }).response;
      const data = await response.body.json();
      return data as Employee;
    } catch (error) {
      console.error('Error creating employee:', error);
      throw error;
    }
  },

  async update(employee: UpdateEmployeeRequest): Promise<Employee> {
    try {
      const headers = await getAuthHeaders();
      const response = await put({
        apiName: API_NAME,
        path: '/employee',
        options: {
          headers,
          body: employee
        }
      }).response;
      const data = await response.body.json();
      return data as Employee;
    } catch (error) {
      console.error('Error updating employee:', error);
      throw error;
    }
  },

  async delete(id: string): Promise<void> {
    try {
      const headers = await getAuthHeaders();
      await del({
        apiName: API_NAME,
        path: `/employee/${id}`,
        options: {
          headers
        }
      }).response;
    } catch (error) {
      console.error('Error deleting employee:', error);
      throw error;
    }
  }
};

// Token API
export const tokenService = {
  async getAll(): Promise<Token[]> {
    try {
      const headers = await getAuthHeaders();
      const response = await get({
        apiName: API_NAME,
        path: '/token',
        options: {
          headers
        }
      }).response;
      const data = await response.body.json();
      return data as Token[];
    } catch (error) {
      console.error('Error fetching tokens:', error);
      throw error;
    }
  },

  async create(tokenData: CreateTokenRequest): Promise<Token> {
    try {
      const headers = await getAuthHeaders();
      const response = await post({
        apiName: API_NAME,
        path: '/token',
        options: {
          headers,
          body: tokenData
        }
      }).response;
      const data = await response.body.json();
      return data as Token;
    } catch (error) {
      console.error('Error creating token:', error);
      throw error;
    }
  },

  async update(token: Token): Promise<Token> {
    try {
      const headers = await getAuthHeaders();
      const updateRequest: UpdateTokenRequest = {
        id: token.id,
        employee_id: token.employee_id
      };
      const response = await put({
        apiName: API_NAME,
        path: '/token',
        options: {
          headers,
          body: updateRequest
        }
      }).response;
      const data = await response.body.json();
      return data as Token;
    } catch (error) {
      console.error('Error updating token:', error);
      throw error;
    }
  },

  async delete(id: string): Promise<void> {
    try {
      const headers = await getAuthHeaders();
      await del({
        apiName: API_NAME,
        path: `/token/${id}`,
        options: {
          headers,
        }
      }).response;
    } catch (error) {
      console.error('Error deleting token:', error);
      throw error;
    }
  }
};

// Event API
export const eventService = {
  async getByToken(token: string): Promise<Event[]> {
    try {
      const headers = await getAuthHeaders();
      const response = await get({
        apiName: API_NAME,
        path: `/events?token=${token}`,
        options: {
          headers
        }
      }).response;
      const data = await response.body.json();
      return data as Event[];
    } catch (error) {
      console.error('Error fetching events:', error);
      throw error;
    }
  },

  async delete(token_id: string, timestamp: string): Promise<void> {
    try {
      const headers = await getAuthHeaders();

      await del({
        apiName: API_NAME,
        path: `/events?token=${token_id}&timestamp=${timestamp}`,
        options: {
          headers
        }
      }).response;
    } catch (error) {
      console.error('Error deleting event:', error);
      throw error;
    }
  }
};