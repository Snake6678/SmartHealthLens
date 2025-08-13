import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader

class RPpgDataset(Dataset):
    def __init__(self, n=2000, length=600):
        # Dummy synthetic dataset: sine waves with noise to simulate HR in 40–180 bpm
        self.X = []
        self.y = []
        fs = 30.0
        for _ in range(n):
            hr = np.random.uniform(60, 120)
            f = hr / 60.0
            t = np.arange(length) / fs
            x = np.sin(2*np.pi*f*t) + 0.2*np.random.randn(length)
            self.X.append(x.astype(np.float32))
            self.y.append(hr.astype(np.float32))
        self.X = np.stack(self.X)
        self.y = np.array(self.y)

    def __len__(self): return len(self.X)
    def __getitem__(self, i): return self.X[i], self.y[i]

class TinyNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv1d(1, 8, 7, padding=3), nn.ReLU(),
            nn.MaxPool1d(2),
            nn.Conv1d(8, 16, 5, padding=2), nn.ReLU(),
            nn.MaxPool1d(2),
            nn.Conv1d(16, 32, 3, padding=1), nn.ReLU(),
            nn.AdaptiveAvgPool1d(1),
        )
        self.head = nn.Linear(32, 1)
    def forward(self, x):
        x = self.net(x)  # B, C, 1
        x = x.squeeze(-1)  # B, C
        return self.head(x).squeeze(-1)  # B

def train():
    ds = RPpgDataset()
    dl = DataLoader(ds, batch_size=64, shuffle=True)
    model = TinyNet()
    opt = torch.optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.L1Loss()
    for epoch in range(5):
        for x, y in dl:
            x = x.unsqueeze(1)  # B, 1, T
            pred = model(x)
            loss = loss_fn(pred, y)
            opt.zero_grad(); loss.backward(); opt.step()
        print(f"epoch {epoch+1}: loss={loss.item():.4f}")
    torch.save(model.state_dict(), "tinynet.pth")
    print("Saved tinynet.pth")

if __name__ == "__main__":
    train()
