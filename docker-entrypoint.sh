#!/bin/bash


nohup yarn chain>chain.log 2>&1 &
sleep 20
yarn deploy-all 
