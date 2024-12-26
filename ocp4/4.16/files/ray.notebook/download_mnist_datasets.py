# Copyright 2022 IBM, Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
from torchvision.datasets import MNIST
from torchvision import transforms


def download_mnist_dataset(destination_dir):
    # Ensure the destination directory exists
    if not os.path.exists(destination_dir):
        os.makedirs(destination_dir)

    # Define transformations
    transform = transforms.Compose(
        [transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))]
    )

    # Download the training data
    train_set = MNIST(
        root=destination_dir, train=True, download=True, transform=transform
    )

    # Download the test data
    test_set = MNIST(
        root=destination_dir, train=False, download=True, transform=transform
    )

    print(f"MNIST dataset downloaded in {destination_dir}")


# Specify the directory where you
destination_dir = os.path.dirname(os.path.abspath(__file__))

download_mnist_dataset(destination_dir)
