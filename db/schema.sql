CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table for Employees
CREATE TABLE IF NOT EXISTS employees ( 
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for Tokens (assuming it was also created successfully in a prior run)
CREATE TABLE IF NOT EXISTS tokens ( 
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add indexes for common lookup patterns to improve performance
CREATE INDEX IF NOT EXISTS idx_employees_email ON employees (email);
CREATE INDEX IF NOT EXISTS idx_tokens_employee_id ON tokens (employee_id);