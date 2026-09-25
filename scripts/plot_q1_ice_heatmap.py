from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LinearSegmentedColormap, Normalize
ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "q1_ice_heatmap_data.npz"
OUT_PDF = ROOT / "figures" / "p1_ice_profile.pdf"
OUT_CROPPED = ROOT / "figures" / "p1_ice_profile_cropped.pdf"
OUT_PREVIEW = ROOT.parent / "tmp" / "pdfs" / "ice-heatmap" / "p1_ice_heatmap_preview.png"
OUT_PREVIEW.parent.mkdir(parents=True, exist_ok=True)


mpl.rcParams.update(
    {
        "font.family": ["Times New Roman", "SimSun"],
        "font.size": 8,
        "axes.titlesize": 8,
        "axes.labelsize": 8,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "mathtext.fontset": "stix",
        "axes.unicode_minus": False,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
    }
)


data = np.load(DATA)
t20 = np.asarray(data["t20"], dtype=float).reshape(-1)
ice20 = np.asarray(data["ice20"], dtype=float)
t25 = np.asarray(data["t25"], dtype=float).reshape(-1)
ice25 = np.asarray(data["ice25"], dtype=float)

vmax = float(max(np.nanmax(ice20), np.nanmax(ice25)))
norm = Normalize(vmin=0.0, vmax=vmax)
cmap = LinearSegmentedColormap.from_list(
    "ice_fraction",
    [
        (0.00, "#2166ac"),
        (0.16, "#67a9cf"),
        (0.34, "#d1e5f0"),
        (0.52, "#f7f7f7"),
        (0.74, "#fdd49e"),
        (1.00, "#f16913"),
    ],
)
cmap.set_bad("#eeeeee")

# Five-layer physical grid from pemfc_setup_ice.m. The ice state is defined
# only in the four porous layers; PEM is retained as a blank physical region.
layer_names = ("aGDL", "aCL", "PEM", "cCL", "cGDL")
layer_thickness_um = np.array([150.0, 3.4, 12.0, 11.3, 150.0])
layer_cells = np.array([6, 13, 19, 19, 6])
layer_boundaries_um = np.r_[0.0, np.cumsum(layer_thickness_um)]
layer_centers_um = 0.5 * (
    layer_boundaries_um[:-1] + layer_boundaries_um[1:]
)
x_edges_um = [0.0]
for left, right, ncell in zip(
    layer_boundaries_um[:-1], layer_boundaries_um[1:], layer_cells
):
    x_edges_um.extend(np.linspace(left, right, ncell + 1)[1:])
x_edges_um = np.asarray(x_edges_um)


def expand_to_five_layers(ice):
    full = np.full((ice.shape[0], int(layer_cells.sum())), np.nan)
    full[:, 0:6] = ice[:, 0:6]
    full[:, 6:19] = ice[:, 6:19]
    full[:, 38:57] = ice[:, 19:38]
    full[:, 57:63] = ice[:, 38:44]
    return full


def centers_to_edges(values):
    return np.r_[values[0], 0.5 * (values[:-1] + values[1:]), values[-1]]


ice20_full = expand_to_five_layers(ice20)
ice25_full = expand_to_five_layers(ice25)

fig = plt.figure(figsize=(14 / 2.54, 5.8 / 2.54))
grid = fig.add_gridspec(
    1,
    3,
    width_ratios=[1, 1, 0.055],
    left=0.10,
    right=0.87,
    bottom=0.20,
    top=0.73,
    wspace=0.24,
)
axes = [fig.add_subplot(grid[0, 0])]
axes.append(fig.add_subplot(grid[0, 1], sharex=axes[0], sharey=axes[0]))
cax = fig.add_subplot(grid[0, 2])
meshes = []
for ax, t, ice, title in zip(
    axes,
    (t20, t25),
    (ice20_full, ice25_full),
    ("-20 °C 工况", "-25 °C 工况"),
):
    mesh = ax.pcolormesh(
        x_edges_um,
        centers_to_edges(t),
        ice,
        shading="flat",
        cmap=cmap,
        norm=norm,
        rasterized=True,
    )
    meshes.append(mesh)
    ax.set_title(title, pad=36)
    ax.set_xlabel(r"$x/\mu\mathrm{m}$")
    ax.set_xlim(layer_boundaries_um[0], layer_boundaries_um[-1])
    ax.set_ylim(float(t[0]), float(t[-1]))
    ax.set_xticks(np.arange(0, 301, 50))
    ax.set_yticks(np.arange(0, 36, 5))
    ax.tick_params(direction="in", top=True, right=True, width=0.6, length=2.5)
    for boundary in layer_boundaries_um[1:-1]:
        ax.axvline(
            boundary,
            color="#4d4d4d",
            linewidth=0.65,
            linestyle=(0, (3, 2)),
        )
    for spine in ax.spines.values():
        spine.set_linewidth(0.6)

    label_x_fraction = (0.12, 0.34, 0.50, 0.66, 0.88)
    label_y_fraction = (1.07, 1.15, 1.07, 1.15, 1.07)
    for name, center, text_x, text_y in zip(
        layer_names, layer_centers_um, label_x_fraction, label_y_fraction
    ):
        ax.annotate(
            name,
            xy=(center, 1.0),
            xycoords=ax.get_xaxis_transform(),
            xytext=(text_x, text_y),
            textcoords=ax.transAxes,
            ha="center",
            va="bottom",
            fontsize=8,
            annotation_clip=False,
            arrowprops={
                "arrowstyle": "->",
                "color": "#333333",
                "linewidth": 0.55,
                "shrinkA": 1.5,
                "shrinkB": 1.5,
            },
        )

axes[0].set_ylabel("时间 / s")
axes[1].tick_params(labelleft=False)

cbar = fig.colorbar(meshes[-1], cax=cax)
cbar.set_label("冰体积分数", rotation=270, labelpad=9)
cbar.ax.tick_params(direction="in", width=0.6, length=2.5, labelsize=8)
cbar.outline.set_linewidth(0.6)
cbar.formatter = mpl.ticker.FormatStrFormatter("%.3f")
cbar.update_ticks()

fig.savefig(OUT_PDF, dpi=400)
fig.savefig(OUT_CROPPED, dpi=400)
fig.savefig(OUT_PREVIEW, dpi=220)
plt.close(fig)

print(f"saved: {OUT_CROPPED}")
print(f"shared color scale: 0 to {vmax:.8f}")
