const todoService = require('../services/todoService');

// Get all todos
const getAllTodos = async (req, res, next) => {
  try {
    const todos = await todoService.getAllTodos();
    res.status(200).json(todos);
  } catch (error) {
    next(error);
  }
};

// Get todo by id
const getTodoById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const todo = await todoService.getTodoById(id);
    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.status(200).json(todo);
  } catch (error) {
    next(error);
  }
};

// Create a new todo
const createTodo = async (req, res, next) => {
  try {
    const { title, description } = req.body;
    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }
    const newTodo = await todoService.createTodo(title, description);
    res.status(201).json(newTodo);
  } catch (error) {
    next(error);
  }
};

// Update a todo
const updateTodo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { title, description, completed } = req.body;
    const updatedTodo = await todoService.updateTodo(id, { title, description, completed });
    if (!updatedTodo) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.status(200).json(updatedTodo);
  } catch (error) {
    next(error);
  }
};

// Delete a todo
const deleteTodo = async (req, res, next) => {
  try {
    const { id } = req.params;
    const deleted = await todoService.deleteTodo(id);
    if (!deleted) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllTodos,
  getTodoById,
  createTodo,
  updateTodo,
  deleteTodo,
};
