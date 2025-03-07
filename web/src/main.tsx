import React, { useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import { VisibilityProvider } from './providers/VisibilityProvider';
import WeaponTest from './components/WeaponTest';
import { debugData } from './utils/debugData';
import { isEnvBrowser } from './utils/misc';
import './index.css';

// For browser development, set the UI to visible by default
if (isEnvBrowser()) {
  debugData([
    {
      action: "setVisible",
      data: true
    }
  ]);
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <VisibilityProvider>
      <WeaponTest />
    </VisibilityProvider>
  </React.StrictMode>,
);