import torch
import torch.nn as nn
import ray
from torch.utils.data import DataLoader
from torchvision import datasets
from torchvision.transforms import ToTensor
from ray.train.torch import TorchTrainer
from ray.train import ScalingConfig


def get_dataset():
    return datasets.FashionMNIST(
        root="/tmp/data",
        train=True,
        download=True,
        transform=ToTensor(),
    )


class NeuralNetwork(nn.Module):
    def __init__(self):
        super().__init__()
        self.flatten = nn.Flatten()
        self.linear_relu_stack = nn.Sequential(
            nn.Linear(28 * 28, 512),
            nn.ReLU(),
            nn.Linear(512, 512),
            nn.ReLU(),
            nn.Linear(512, 10),
        )

    def forward(self, inputs):
        inputs = self.flatten(inputs)
        logits = self.linear_relu_stack(inputs)
        return logits


def get_dataset():
    return datasets.FashionMNIST(
        root="/tmp/data",
        train=True,
        download=True,
        transform=ToTensor(),
    )


def train_func_distributed():
    num_epochs = 3
    batch_size = 64

    dataset = get_dataset()
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
    dataloader = ray.train.torch.prepare_data_loader(dataloader)

    model = NeuralNetwork()
    model = ray.train.torch.prepare_model(model)

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.SGD(model.parameters(), lr=0.01)

    for epoch in range(num_epochs):
        if ray.train.get_context().get_world_size() > 1:
            dataloader.sampler.set_epoch(epoch)

        for inputs, labels in dataloader:
            optimizer.zero_grad()
            pred = model(inputs)
            loss = criterion(pred, labels)
            loss.backward()
            optimizer.step()
        print(f"epoch: {epoch}, loss: {loss.item()}")


# For GPU Training, set `use_gpu` to True.
use_gpu = True

# To learn more about configuring S3 compatible storage check out our docs -> https://github.com/project-codeflare/codeflare-sdk/blob/main/docs/s3-compatible-storage.md
trainer = TorchTrainer(
    train_func_distributed,
    scaling_config=ScalingConfig(
        # num_workers = number of worker nodes with the ray head node included
        num_workers=3,
        use_gpu=use_gpu,
        resources_per_worker={
            "CPU": 1,
        },
        trainer_resources={
            "CPU": 0,
        },
    ),
)

results = trainer.fit()
