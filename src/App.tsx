/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { BrowserRouter, Routes, Route } from 'react-router-dom';
import HabitTracker from './components/HabitTracker';
import Layout from './components/Layout';

export default function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<HabitTracker />} />
          <Route path="/settings" element={<HabitTracker />} />
          <Route path="/notifications" element={<HabitTracker />} />
          <Route path="*" element={<HabitTracker />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}
