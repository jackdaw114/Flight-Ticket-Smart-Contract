import logo from './logo.svg';
import './App.css';

import flightRefundArtifact from "../../artifacts/contracts/FlightRefund.sol/FlightRefund.json"

const HARDHAT_NETWORK_ID = '31337';
const ERROR_CODE_TX_REJECTED_BY_USER = 4001;
const contract_address = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
