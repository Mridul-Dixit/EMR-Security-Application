import json
from web3 import Web3
import streamlit as st
import numpy as np
from datetime import datetime
import pytz

ganache_url = "http://127.0.0.1:7545"
web3 = Web3(Web3.HTTPProvider(ganache_url, request_kwargs={'timeout': 60}))

if web3.is_connected():
    print("Connected to Ganache!")
else:
    print("Failed to connect to Ganache.")

contract_address = "0x5AAF6f5FAde0fAc0cF0a02619B477ec5fA208d2F"  #replace with your contract address
with open('build/contracts/EMR_Security.json', 'r') as file:
    contract_json = json.load(file)
    contract_abi= contract_json['abi']

contract = web3.eth.contract(address=contract_address, abi=contract_abi)

def upload_emr(emr, t, from_address):
    try:
        tx_hash = contract.functions.uploadEMR(emr, t).transact({'from': from_address})
        tx_receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        event_logs = contract.events.EMRUploaded().process_receipt(tx_receipt)
        emr_id = event_logs[0]['args']['emrID']
        block_number = event_logs[0]['args']['blockNumber']  
        return emr_id, block_number
    except Exception as e:
        print(f"Error uploading EMR: {str(e)}")


def update_emr(emr_id, shares, change_data, change_message, from_address):
    try:
        tx_hash = contract.functions.updateEMR(emr_id, shares, change_data, change_message).transact({'from': from_address})
        receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
        logs = contract.events.EMRUpdated().process_receipt(receipt)
        updated_emr_id = logs[0]['args']['emrID']
        block_number = logs[0]['args']['blockNumber']
        return updated_emr_id, block_number
    except Exception as e:
        print(f"Error updating EMR: {str(e)}")

def get_emr_data(shares,emr_id):
    try:
        data = contract.functions.getEMRData(shares,emr_id).call()
        return data
    except Exception as e:
        print(f"Error fetching EMR data: {str(e)}")

def get_emr_history(emr_id):
    try:
        history, timestamps, blocks = contract.functions.getEMRHistory(emr_id).call()
        time_stamps = []
        for time in timestamps:
          time_stamps.append(timestamp_to_human_readable(time))
        return history, time_stamps, blocks
    except Exception as e:
        print(f"Error fetching EMR history: {str(e)}")

def get_shares_by_block_number(emr_id, block_number):
    try:
        shares = contract.functions.getSharesByBlockNumber(emr_id, block_number).call()
        return shares
    except Exception as e:
        print(f"Error fetching shares by block number: {str(e)}")

def timestamp_to_human_readable(timestamp):
    utc_datetime = datetime.utcfromtimestamp(timestamp)
    utc_timezone = pytz.timezone('UTC')
    utc_datetime = utc_timezone.localize(utc_datetime)
    ist_timezone = pytz.timezone('Asia/Kolkata')
    ist_datetime = utc_datetime.astimezone(ist_timezone)

    return ist_datetime.strftime('%Y-%m-%d %H:%M:%S %Z')
from_address = "0x1000297FDFAF77AA29665AC25D0bFeDB9aB41aeb" # Replace with your address 
def main():
    st.title("EMR Blockchain Interface")
    task = st.selectbox("Select Task", ["Upload EMR", "Update EMR", "Get EMR Data", "Get EMR History", "Get Shares by Block Number"])

    if task == "Upload EMR":
        emr = st.text_input("EMR Data")
        t = st.number_input("Parameter t", min_value=0, step=1)
        if st.button("Upload EMR"):
            emr_id, block_number = upload_emr(emr, t, from_address)
            st.write(f"EMR ID: {emr_id}, Block Number: {block_number}")

    elif task == "Update EMR":
        emr_id = st.number_input("EMR ID", min_value=0, step=1)
        shares = st.text_area("Shares (comma-separated integers)").split(',')
        change_data = st.text_input("Change Data")
        change_message = st.text_input("Change Message")
        if st.button("Update EMR"):
            shares = list(map(int, shares))
            updated_emr_id, block_number = update_emr(emr_id, shares, change_data, change_message, from_address)
            st.write(f"Updated EMR ID: {updated_emr_id}, Block Number: {block_number}")

    elif task == "Get EMR Data":
        emr_id = st.number_input("EMR ID", min_value=0, step=1)
        shares = st.text_area("Shares (comma-separated integers)").split(',')
        if st.button("Get EMR Data"):
            shares = list(map(int, shares))
            data = get_emr_data(shares, emr_id)
            st.write(f"EMR Data: {data}")

    elif task == "Get EMR History":
        emr_id = st.number_input("EMR ID", min_value=0, step=1)
        if st.button("Get EMR History"):
            history, timestamps, blocks = get_emr_history(emr_id)
            st.write(f"EMR History: {history}")
            st.write(f"Timestamps: {timestamps}")
            st.write(f"Blocks: {blocks}")

    elif task == "Get Shares by Block Number":
        emr_id = st.number_input("EMR ID", min_value=0, step=1)
        block_number = st.number_input("Block Number", min_value=0, step=1)
        if st.button("Get Shares"):
            shares = get_shares_by_block_number(emr_id, block_number)
            st.write(f"Shares: {shares}")

if __name__ == "__main__":
    main()

