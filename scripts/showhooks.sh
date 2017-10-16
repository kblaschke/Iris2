#!/bin/bash

fgrep 'NotifyListener("' ../lua/*/*.lua ../lua/*.lua | awk '{print $2}' | awk -F \" '{print $2}' | sort | uniq

