import React from 'react';
import ReactDOM from 'react-dom/client';
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import './index.css';
import F12Main from './F12Main';

import Page from './pages/Page';
import Page1 from './pages/Page1';


const router = createBrowserRouter([
  { path: '/', element: <F12Main /> },
{ path: '/Page', element: <Page /> },
{ path: '/Page1', element: <Page1 /> },
]);

export default function App() {
  return (
    <RouterProvider router={router} />
  );
}