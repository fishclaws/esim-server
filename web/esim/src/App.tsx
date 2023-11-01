import React from 'react';
import logo from './logo.svg';
import './App.css';
import { ChangeEvent } from 'react';
import ImageUpload from "./components/ImageUpload";


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
        <div className='centered'>
          <h2>1</h2>
          <div className='screenshot-holder'>
            <img className="screenshot" src="./Screenshot.png"></img>
          </div>
          <br></br>
          <a className="button-23" href="https://twitter.com/HashashinTag/status/1718396516635754998">link to thread</a>
          <br></br>
          <br></br>
          <a className='button-23' href="https://www.getnomad.app/">link to Nomad.app</a>
        </div>
        <div className='centered'>
          <br></br>
          <h2>2</h2>
          <h3>Upload Screenshot of QR code here</h3>
          <ImageUpload />
          <h2>3</h2>
          <h3>We'll provide them to reporters and civilians in Gaza to distribute</h3>
        </div>

      </div>
    </div>
  );
}

export default App;
