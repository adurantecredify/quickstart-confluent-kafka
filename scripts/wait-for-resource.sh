#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Specifically, this script is intended SOLELY to support the Confluent
# Quick Start offering in Amazon Web Services. It is not recommended
# for use in any other production environment.
#
#
#
#
# Simple script to wait for a Cloudformation resource
#
# usage:
#	$0 [ stack-name ] ResourceName
#
# If no stack is given, we try to figure out out from tags of this
# instance.
#

murl_top=http://169.254.169.254/latest/meta-data

ThisInstance=$(curl -f $murl_top/instance-id 2> /dev/null)
if [ -z "$ThisInstance" ] ; then
	ThisInstance="unknown"
fi

ThisRegion=$(curl -f $murl_top/placement/availability-zone 2> /dev/null)
if [ -z "$ThisRegion" ] ; then
	ThisRegion="us-east-1"
else
	ThisRegion="${ThisRegion%[a-z]}"
fi

if [ -n "${1}" ] ; then
    if [ -z "${2}" ] ; then
	ThisStack=$(aws ec2 describe-instances --region $ThisRegion --output text --instance-ids $ThisInstance --query 'Reservations[].Instances[].Tags[?Key==`aws:cloudformation:stack-name`].Value ')
	ThisResource=$1
    else
	ThisStack=$1
	ThisResource=$2
    fi
fi

if [ -z "$ThisStack" ] ; then
	echo "No AWS Cloudformation Stack specified; aborting script"
	exit 1
elif [ -z "$ThisRegion" ] ; then
	echo "Failed to determine AWS region; aborthing script"
	exit 1
fi

# Wait for all nodes to come on-line within a group
#
resourceStatus=$(aws cloudformation describe-stack-resources \
	--output text \
	--region $ThisRegion \
	--stack-name $ThisStack \
	--logical-resource-id $ThisResource \
	--query StackResources[].ResourceStatus)

if [ -z "$resourceStatus" ] ; then
	echo "$ThisResource has does not exist in $ThisStack"
	exit 0
fi

## TBD ... add timeout (optional, since CFT will enforce timeout)
#
while [ $resourceStatus != "CREATE_COMPLETE" ]
do
    sleep 30
    resourceStatus=$(aws cloudformation describe-stack-resources \
	--output text \
	--region $ThisRegion \
	--stack-name $ThisStack \
	--logical-resource-id $ThisResource \
	--query StackResources[].ResourceStatus)
done

echo "$ThisResource has status $resourceStatus"

