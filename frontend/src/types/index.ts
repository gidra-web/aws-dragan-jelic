export interface Employee {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  created_at?: string;
}

export interface Token {
  id: string;
  employee_id: string;
  issued_at?: string;
}

export interface Event {
  authorized: boolean;
  token_id: string;
  timestamp: string;
}

export interface CreateEmployeeRequest {
  first_name: string;
  last_name: string;
  email: string;
}

export interface UpdateEmployeeRequest {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
}

export interface DeleteEmployeeRequest {
  id: string;
}

export interface CreateTokenRequest {
  employee_id: string;
}

export interface UpdateTokenRequest {
  id: string;
  employee_id: string;
}

export interface DeleteTokenRequest {
  id: string;
}

export interface DeleteEventRequest {
  token_id: string;
  timestamp: string;
}

export interface CreateEventRequest {
  token: string;
}