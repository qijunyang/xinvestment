// In-memory database (for example purposes)
let todos = [
  { id: 1, title: 'Learn Express', description: 'Study Express.js framework', completed: false },
  { id: 2, title: 'Build API', description: 'Create a REST API', completed: false },
];

let nextId = 3;

// Get all todos
const getAllTodos = async () => {
  return todos;
};

// Get todo by id
const getTodoById = async (id) => {
  return todos.find(todo => todo.id === parseInt(id));
};

// Create a new todo
const createTodo = async (title, description) => {
  const newTodo = {
    id: nextId++,
    title,
    description,
    completed: false,
  };
  todos.push(newTodo);
  return newTodo;
};

// Update a todo
const updateTodo = async (id, updateData) => {
  const todoIndex = todos.findIndex(todo => todo.id === parseInt(id));
  if (todoIndex === -1) {
    return null;
  }
  todos[todoIndex] = { ...todos[todoIndex], ...updateData, id: parseInt(id) };
  return todos[todoIndex];
};

// Delete a todo
const deleteTodo = async (id) => {
  const todoIndex = todos.findIndex(todo => todo.id === parseInt(id));
  if (todoIndex === -1) {
    return false;
  }
  todos.splice(todoIndex, 1);
  return true;
};

module.exports = {
  getAllTodos,
  getTodoById,
  createTodo,
  updateTodo,
  deleteTodo,
};
