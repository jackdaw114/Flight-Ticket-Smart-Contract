
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FlightRefund {
    address public owner;
    uint256 public constant MINIMUM_DELAY = 30 minutes;

    struct Ticket {
        address passenger;
        uint256 price; // Price stored in ETH
        bool refunded;
    }

    struct Flight {
        uint256 ticketPrice; // Ticket price in ETH
        bool isActive;
    }

    mapping(bytes32 => Flight) public flights;
    mapping(bytes32 => Ticket[]) public tickets;

    event FlightAdded(bytes32 indexed flightNumber, uint256 ticketPriceInEth);
    event FlightUpdated(bytes32 indexed flightNumber, uint256 newTicketPriceInEth);
    event TicketsPurchased(
        bytes32 indexed flightNumber,
        address indexed passenger,
        uint256 numberOfTickets,
        uint256 totalPriceInEth
    );
    event RefundIssued(bytes32 indexed flightNumber, address indexed passenger, uint256 amountInEth);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier flightExists(bytes32 flightNumber) {
        require(flights[flightNumber].isActive, "Flight does not exist");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    bool private _locked;

    function addFlight(bytes32 flightNumber, uint256 ticketPriceInEth) external onlyOwner {
        require(!flights[flightNumber].isActive, "Flight already exists");
        flights[flightNumber] = Flight(ticketPriceInEth * 1 ether, true); // Store as Wei
        emit FlightAdded(flightNumber, ticketPriceInEth);
    }

    function updateFlightPrice(bytes32 flightNumber, uint256 newTicketPriceInEth)
        external
        onlyOwner
        flightExists(flightNumber)
    {
        flights[flightNumber].ticketPrice = newTicketPriceInEth * 1 ether; // Store as Wei
        emit FlightUpdated(flightNumber, newTicketPriceInEth);
    }

    function purchaseTickets(bytes32 flightNumber, uint256 numberOfTickets)
        external
        payable
        flightExists(flightNumber)
    {
        require(numberOfTickets > 0, "Must purchase at least one ticket");

        uint256 totalCost = flights[flightNumber].ticketPrice * numberOfTickets;
        require(msg.value == totalCost, "Incorrect payment amount");

        for (uint256 i = 0; i < numberOfTickets; i++) {
            tickets[flightNumber].push(
                Ticket({
                    passenger: msg.sender,
                    price: flights[flightNumber].ticketPrice,
                    refunded: false
                })
            );
        }

        emit TicketsPurchased(flightNumber, msg.sender, numberOfTickets, totalCost / 1 ether);
    }

    function processRefund(bytes32 flightNumber, uint256 delayInMinutes, uint256 refundPercentage)
        external
        flightExists(flightNumber)
        nonReentrant
    {
        require(delayInMinutes >= MINIMUM_DELAY / 1 minutes, "Delay must be at least 30 minutes");
        require(refundPercentage > 0 && refundPercentage <= 100, "Invalid refund percentage");

        uint256 totalRefund = 0;

        for (uint256 i = 0; i < tickets[flightNumber].length; i++) {
            Ticket storage ticket = tickets[flightNumber][i];
            if (ticket.passenger == msg.sender && !ticket.refunded) {
                uint256 refundAmount = (ticket.price * refundPercentage) / 100;
                ticket.refunded = true;
                totalRefund += refundAmount;

                emit RefundIssued(flightNumber, ticket.passenger, refundAmount / 1 ether);
            }
        }

        require(totalRefund > 0, "No eligible tickets found for refund");
        payable(msg.sender).transfer(totalRefund);
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function getTicketCount(bytes32 flightNumber, address passenger) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < tickets[flightNumber].length; i++) {
            if (tickets[flightNumber][i].passenger == passenger) {
                count++;
            }
        }
        return count;
    }
}