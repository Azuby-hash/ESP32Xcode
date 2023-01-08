//
//  ViewController.swift
//  BLEConnection
//
//  Created by Azuby on 07/01/2023.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    @IBOutlet weak var connectB: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var statusT: UILabel!
    @IBOutlet weak var detailT: UIStackView!
    
    var centralManager: CBCentralManager!
    var bluefruitPeripheral: CBPeripheral!
    
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    @IBAction func connect(_ g: UITapGestureRecognizer) {
        g.view?.clickAnimation(toggleColor: .purple)
        
        if connectB.text == "Connect" {
            startScanning()
        } else {
            disconnectFromDevice()
        }
    }
    @IBAction func detail(_ g: UITapGestureRecognizer) {
        g.view?.clickAnimation(toggleColor: .purple)
        detailT.alpha = detailT.alpha < 0.5 ? 1 : 0
    }
    @IBAction func switchLed(_ sw: UISwitch) {
        writeOutgoingValue(data: "\(sw.isOn)")
    }
}

extension ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
        switch central.state {
          case .poweredOff:
              print("Is Powered Off.")
          case .poweredOn:
              print("Is Powered On.")
          case .unsupported:
              print("Is Unsupported.")
          case .unauthorized:
              print("Is Unauthorized.")
          case .unknown:
              print("Unknown")
          case .resetting:
              print("Resetting")
          @unknown default:
              print("Error")
        }
    }
    
    func startScanning() {
        // Start Scanning
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        bluefruitPeripheral = peripheral

        bluefruitPeripheral.delegate = self

        print("Peripheral name: \(peripheral.name ?? "")")
        
        centralManager?.connect(bluefruitPeripheral!, options: nil)
        
        centralManager?.stopScan()
    }
}

extension ViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bluefruitPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
        connectB.text = "Disconnect"
        deviceName.text = "Device Name: \(peripheral.name ?? "")"
        statusT.text = "Status: Connected"
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectB.text = "Connect"
        deviceName.text = "Device Name: None"
        statusT.text = "Status: Disconnected"
    }
    func disconnectFromDevice () {
        if bluefruitPeripheral != nil {
            centralManager?.cancelPeripheralConnection(bluefruitPeripheral!)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        print("1*******************************************************")

        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
//        print("Discovered Services: \(services)")
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           
//        print("2*******************************************************")
        
        guard let characteristics = service.characteristics else {
            return
        }

        print("Found \(characteristics.count) characteristics.")

        for characteristic in characteristics {
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {

              rxCharacteristic = characteristic

              peripheral.setNotifyValue(true, for: rxCharacteristic!)
              peripheral.readValue(for: characteristic)

//              print("RX Characteristic: \(rxCharacteristic.uuid)")
            }

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
              
              txCharacteristic = characteristic
              
//              print("TX Characteristic: \(txCharacteristic.uuid)")
            }
        }
    }
    func writeOutgoingValue(data: String){
          
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)

        if let bluefruitPeripheral = bluefruitPeripheral,
           let txCharacteristic = txCharacteristic
        {
          
            bluefruitPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral Is Powered On.")
        case .unsupported:
            print("Peripheral Is Unsupported.")
        case .unauthorized:
            print("Peripheral Is Unauthorized.")
        case .unknown:
            print("Peripheral Unknown")
        case .resetting:
            print("Peripheral Resetting")
        case .poweredOff:
            print("Peripheral Is Powered Off.")
        @unknown default:
            print("Error")
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        var characteristicASCIIValue = NSString()

        guard characteristic == rxCharacteristic,

        let characteristicValue = characteristic.value,
        let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }

        characteristicASCIIValue = ASCIIstring

        print("Value Recieved: \((characteristicASCIIValue as String))")
    }
}

struct CBUUIDs {

    static let kBLEService_UUID = "91bad492-b950-4226-aa2b-4ede9fa42f59"
    static let kBLE_Characteristic_uuid_Tx = "ca73b3ba-39f6-4ab3-91ae-186dc9577d99"
    static let kBLE_Characteristic_uuid_Rx = "ca73b3ba-39f6-4ab3-91ae-186dc9577d99"

    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
    static let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

}
