import React from 'react';
import logo from './logo.svg';
import './App.css';
import { ChangeEvent } from 'react';
import ImageUpload from "./components/ImageViewer";
import ImageViewer from './components/ImageViewer';


function App() {
  return (
    <div className="App">

      <header className="App-header">
        <br></br>
        GAZA E-SIMs
        <h6>buy and upload an E-Sim and we'll get it to someone in Gaza</h6>
        <div className="flag">

          <div className="background">
            <div className="top"></div>
            <div className="middle"></div>
            <div className="triangle"></div>
          </div>

        </div>
      </header>
      <div className='col-wrapper'>
        <h1>QR Codes</h1>
        <ImageViewer></ImageViewer>
      </div>
    </div>
  );
}

export default App;
