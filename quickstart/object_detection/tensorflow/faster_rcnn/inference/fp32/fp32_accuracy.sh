#!/usr/bin/env bash
#
# Copyright (c) 2020 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

MODEL_DIR=${MODEL_DIR-$PWD}

echo 'MODEL_DIR='$MODEL_DIR
echo 'OUTPUT_DIR='$OUTPUT_DIR
echo 'DATASET_DIR='$DATASET_DIR

if [[ -z ${OUTPUT_DIR} ]]; then
  echo "The required environment variable OUTPUT_DIR has not been set"
  exit 1
fi

# Create the output directory in case it doesn't already exist
mkdir -p ${OUTPUT_DIR}

if [[ -z ${DATASET_DIR} ]]; then
  echo "The required environment variable DATASET_DIR has not been set"
  exit 1
fi

if [[ ! -d ${DATASET_DIR} ]]; then
  echo "The DATASET_DIR '${DATASET_DIR}' does not exist"
  exit 1
fi

if [[ -z ${TF_MODELS_DIR} ]]; then
  echo "The required environment variable TF_MODELS_DIR has not been set"
  exit 1
fi

if [[ ! -d ${TF_MODELS_DIR} ]]; then
  echo "The TF_MODELS_DIR '${TF_MODELS_DIR}' does not exist"
  exit 1
fi

# If a path to the pretrained model dir was not provided, unzip the pretrained
# model from the model package
if [[ -z ${PRETRAINED_MODEL_DIR} ]]; then
  tar -xvf ${MODEL_DIR}/faster_rcnn_resnet50_fp32_coco_pretrained_model.tar.gz
  PRETRAINED_MODEL_DIR=${MODEL_DIR}/faster_rcnn_resnet50_fp32_coco

  # Replace paths in the pipeline config file
  sed -i.bak 128s+/checkpoints+$PRETRAINED_MODEL_DIR+ ${PRETRAINED_MODEL_DIR}/pipeline.config
  sed -i.bak 132s+/dataset+$DATASET_DIR+ ${PRETRAINED_MODEL_DIR}/pipeline.config
fi

if [[ ! ${PRETRAINED_MODEL_DIR} ]]; then
  echo "The pretrained model directory (${PRETRAINED_MODEL_DIR}) does not exist."
  exit 1
fi

source "$(dirname $0)/common/utils.sh"
_command python ${MODEL_DIR}/benchmarks/launch_benchmark.py \
  --model-name faster_rcnn \
  --mode inference \
  --precision fp32 \
  --framework tensorflow \
  --model-source-dir ${TF_MODELS_DIR} \
  --output-dir ${OUTPUT_DIR} \
  --data-location ${DATASET_DIR} \
  --in-graph ${PRETRAINED_MODEL_DIR}/frozen_inference_graph.pb \
  --accuracy-only \
  $@
