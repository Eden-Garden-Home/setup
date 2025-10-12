import plotly.graph_objects as go
import numpy as np

# Create concentric circles for defense in depth with expanded spacing for better readability
fig = go.Figure()

# Define layer properties (from outermost to innermost) using exact names from data
layers = [
    {"name": "Perimeter", "radius": 5.5, "color": "#1FB8CD", "components": ["Cloudflare WAF", "Tailscale VPN", "Proxmox Firewall"]},
    {"name": "Network", "radius": 4.4, "color": "#DB4545", "components": ["Docker Networks", "VLAN Segmentation", "Internal Networks"]},
    {"name": "Application", "radius": 3.3, "color": "#2E8B57", "components": ["Traefik Proxy", "Authentik SSO", "TLS Termination"]},
    {"name": "Container", "radius": 2.2, "color": "#5D878F", "components": ["Non-priv cont", "Read-only FS", "Resource limits"]},
    {"name": "Data", "radius": 1.1, "color": "#D2BA4C", "components": ["Encrypted vol", "Secure secrets", "DB isolation"]}
]

# Add filled concentric circles with transparency
for i, layer in enumerate(layers):
    theta = np.linspace(0, 2*np.pi, 100)
    x_circle = layer["radius"] * np.cos(theta)
    y_circle = layer["radius"] * np.sin(theta)
    
    fig.add_trace(go.Scatter(
        x=x_circle, y=y_circle,
        mode='lines',
        fill='tonexty' if i > 0 else 'toself',
        fillcolor=f"rgba({int(layer['color'][1:3], 16)}, {int(layer['color'][3:5], 16)}, {int(layer['color'][5:7], 16)}, 0.2)",
        line=dict(color=layer["color"], width=4),
        name=f'{layer["name"]} Layer',
        showlegend=True,
        hoverinfo='skip'
    ))

# Add layer labels positioned with expanded spacing
label_positions = [
    {"layer": "Perimeter", "x": 0, "y": 5.8},
    {"layer": "Network", "x": -4.0, "y": 4.0},
    {"layer": "Application", "x": 3.0, "y": 3.0},
    {"layer": "Container", "x": -2.0, "y": -2.0},
    {"layer": "Data", "x": 0, "y": 1.5}
]

for pos in label_positions:
    layer = next(l for l in layers if l["name"] == pos["layer"])
    fig.add_annotation(
        x=pos["x"], y=pos["y"],
        text=f"<b>{layer['name']}</b>",
        showarrow=False,
        font=dict(size=14, color=layer["color"]),
        bgcolor='white',
        bordercolor=layer["color"],
        borderwidth=2,
        borderpad=4
    )

# Add key components for each layer with expanded spacing
component_positions = [
    # Perimeter layer
    {"text": "Cloudflare WAF", "x": -5.2, "y": 2.0, "color": "#1FB8CD"},
    {"text": "Tailscale VPN", "x": 5.2, "y": 2.0, "color": "#1FB8CD"},
    {"text": "Proxmox Firewall", "x": 0, "y": -5.2, "color": "#1FB8CD"},
    
    # Network layer
    {"text": "Docker Networks", "x": -4.4, "y": 1.0, "color": "#DB4545"},
    {"text": "VLAN Segment", "x": 4.4, "y": 1.0, "color": "#DB4545"},
    {"text": "Internal Nets", "x": 0, "y": -4.4, "color": "#DB4545"},
    
    # Application layer
    {"text": "Traefik Proxy", "x": -3.3, "y": 0.7, "color": "#2E8B57"},
    {"text": "Authentik SSO", "x": 3.3, "y": 0.7, "color": "#2E8B57"},
    {"text": "TLS Term", "x": 0, "y": -3.3, "color": "#2E8B57"},
    
    # Container layer
    {"text": "Non-priv cont", "x": -2.0, "y": 0.4, "color": "#5D878F"},
    {"text": "Read-only FS", "x": 2.0, "y": 0.4, "color": "#5D878F"},
    {"text": "Resource limits", "x": 0, "y": -2.0, "color": "#5D878F"},
]

for comp in component_positions:
    fig.add_annotation(
        x=comp["x"], y=comp["y"],
        text=comp["text"],
        showarrow=False,
        font=dict(size=11, color='black'),
        bgcolor='rgba(255,255,255,0.9)',
        bordercolor=comp["color"],
        borderwidth=1,
        borderpad=2
    )

# Add central protected assets with better visibility
fig.add_trace(go.Scatter(
    x=[0], y=[0],
    mode='markers+text',
    marker=dict(size=60, color='#FFD700', line=dict(color='black', width=3)),
    text='<b>Protected<br>Assets</b>',
    textfont=dict(size=14, color='black'),
    textposition='middle center',
    name='Protected Assets',
    showlegend=False
))

# Add simplified attack arrows with expanded spacing
attack_arrows = [
    {"start": (6.5, 2.5), "end": (5.8, 2.0), "text": "External Threats", "angle": 0},
    {"start": (2.5, 6.5), "end": (1.8, 5.8), "text": "Bot Attacks", "angle": 45},
    {"start": (-6.5, -2.5), "end": (-5.8, -2.0), "text": "DDoS", "angle": 180},
    {"start": (-2.5, -6.5), "end": (-1.8, -5.8), "text": "Unauthorized", "angle": 225}
]

for i, arrow in enumerate(attack_arrows):
    fig.add_annotation(
        x=arrow["end"][0], y=arrow["end"][1],
        ax=arrow["start"][0], ay=arrow["start"][1],
        xref='x', yref='y',
        axref='x', ayref='y',
        showarrow=True,
        arrowhead=3,
        arrowsize=1.5,
        arrowwidth=3,
        arrowcolor='#CC0000'
    )
    
    fig.add_annotation(
        x=arrow["start"][0], y=arrow["start"][1],
        text=arrow["text"],
        showarrow=False,
        font=dict(size=12, color='#CC0000'),
        bgcolor='rgba(255,255,255,0.9)',
        bordercolor='#CC0000',
        borderwidth=1,
        borderpad=3
    )

# Update layout with expanded spacing
fig.update_layout(
    xaxis=dict(
        range=[-7, 7],
        showgrid=False,
        showticklabels=False,
        zeroline=False
    ),
    yaxis=dict(
        range=[-7, 7],
        showgrid=False,
        showticklabels=False,
        zeroline=False,
        scaleanchor="x",
        scaleratio=1
    ),
    showlegend=True,
    legend=dict(
        orientation='h',
        yanchor='bottom',
        y=1.02,
        xanchor='center',
        x=0.5
    ),
    plot_bgcolor='white',
    paper_bgcolor='white'
)

fig.write_image("security_layers_expanded_highres.png", width=1920, height=1080, scale=1)
fig.write_image("security_layers_expanded_highres.svg", format="svg")

