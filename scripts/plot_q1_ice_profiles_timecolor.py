from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import Normalize


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "q1_ice_heatmap_data.npz"
OUT_PDF = ROOT / "figures" / "p1_ice_profiles_timecolor.pdf"
OUT_PREVIEW = (
    ROOT.parent
    / "tmp"
    / "pdfs"
    / "ice-timecolor"
    / "p1_ice_profiles_timecolor_preview.png"
)
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

tmin_color = 20.0
tmax_color = 35.0
norm = Normalize(vmin=tmin_color, vmax=tmax_color, clip=True)
cmap = mpl.colormaps["turbo"]

# The stored model states are 0.2 s apart. Intermediate 0.1 s profiles are
# linearly interpolated to make the time-colored bands visually continuous.
target_times = np.linspace(tmin_color, tmax_color, 151)
shared_vmax = float(
    max(
        np.nanmax(ice20[(t20 >= tmin_color) & (t20 <= tmax_color)]),
        np.nanmax(ice25[(t25 >= tmin_color) & (t25 <= tmax_color)]),
    )
)

fig = plt.figure(figsize=(14 / 2.54, 5.2 / 2.54))
grid = fig.add_gridspec(
    1,
    3,
    width_ratios=[1, 1, 0.055],
    left=0.10,
    right=0.87,
    bottom=0.22,
    top=0.88,
    wspace=0.24,
)
axes = [fig.add_subplot(grid[0, 0])]
axes.append(fig.add_subplot(grid[0, 1], sharex=axes[0], sharey=axes[0]))
cax = fig.add_subplot(grid[0, 2])

for ax, t, ice, title in zip(
    axes,
    (t20, t25),
    (ice20, ice25),
    ("-20 °C 工况", "-25 °C 工况"),
):
    x = np.arange(1, ice.shape[1] + 1)
    profiles = np.column_stack(
        [np.interp(target_times, t, ice[:, column]) for column in range(ice.shape[1])]
    )

    for lower, upper, time_lower, time_upper in zip(
        profiles[:-1], profiles[1:], target_times[:-1], target_times[1:]
    ):
        ax.fill_between(
            x,
            np.minimum(lower, upper),
            np.maximum(lower, upper),
            where=np.maximum(lower, upper) > np.minimum(lower, upper) + 1e-12,
            color=cmap(norm(0.5 * (time_lower + time_upper))),
            linewidth=0,
            edgecolor="none",
            antialiased=False,
            interpolate=True,
            rasterized=True,
        )

    ax.axvline(
        38.5,
        color="#000000",
        linewidth=0.85,
        linestyle=(0, (3, 2)),
        zorder=12,
    )
    ax.set_title(title, pad=3)
    ax.set_xlabel("多孔介质网格单元编号")
    ax.set_xlim(19.5, 44.5)
    ax.set_ylim(0.0, 1.06 * shared_vmax)
    ax.set_xticks([20, 25, 30, 35, 40, 44])
    ax.yaxis.set_major_locator(mpl.ticker.MaxNLocator(nbins=5, min_n_ticks=4))
    ax.yaxis.set_major_formatter(mpl.ticker.FormatStrFormatter("%.3f"))
    ax.set_axisbelow(True)
    ax.grid(True, color="#d9d9d9", linewidth=0.45, alpha=0.75)
    ax.tick_params(direction="in", top=True, right=True, width=0.6, length=2.5)
    for spine in ax.spines.values():
        spine.set_linewidth(0.6)

    axis_transform = ax.get_xaxis_transform()
    for name, x_left, x_right in (("cCL", 20.0, 38.5), ("cGDL", 38.5, 44.0)):
        ax.annotate(
            "",
            xy=(x_left + 0.15, 0.76),
            xytext=(x_right - 0.15, 0.76),
            xycoords=axis_transform,
            textcoords=axis_transform,
            zorder=14,
            arrowprops={
                "arrowstyle": "<->",
                "color": "#222222",
                "linewidth": 0.65,
                "shrinkA": 0,
                "shrinkB": 0,
            },
        )
        ax.text(
            0.5 * (x_left + x_right),
            0.84,
            name,
            transform=axis_transform,
            ha="center",
            va="center",
            fontsize=8,
            color="#222222",
            zorder=13,
            bbox={
                "facecolor": "white",
                "edgecolor": "none",
                "alpha": 0.78,
                "pad": 0.8,
            },
        )

axes[0].set_ylabel("冰体积分数")
axes[1].tick_params(labelleft=False)

sm = mpl.cm.ScalarMappable(norm=norm, cmap=cmap)
sm.set_array([])
cbar = fig.colorbar(sm, cax=cax)
cbar.ax.set_xlabel(r"$t/\mathrm{s}$", labelpad=3)
cbar.set_ticks(np.arange(tmin_color, tmax_color + 1.0, 5.0))
cbar.ax.tick_params(direction="in", width=0.6, length=2.5, labelsize=8)
cbar.outline.set_linewidth(0.6)

fig.savefig(OUT_PDF, dpi=400)
fig.savefig(OUT_PREVIEW, dpi=220)
plt.close(fig)

print(f"saved: {OUT_PDF}")
print(
    f"profiles: {len(target_times)}; "
    f"time range: {tmin_color:.0f} to {tmax_color:.0f} s"
)
