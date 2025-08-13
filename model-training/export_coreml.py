import torch
import coremltools as ct
from train_stub import TinyNet

def export_coreml():
    model = TinyNet()
    model.load_state_dict(torch.load("tinynet.pth", map_location="cpu"))
    model.eval()
    example = torch.randn(1, 1, 600)
    traced = torch.jit.trace(model, example)
    mlmodel = ct.convert(
        traced,
        inputs=[ct.TensorType(name="input", shape=example.shape)],
    )
    mlmodel.save("TinyHR.mlmodel")
    print("Saved TinyHR.mlmodel")

if __name__ == "__main__":
    export_coreml()
