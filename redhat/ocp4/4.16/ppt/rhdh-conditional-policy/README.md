# RHDH 1.4 Conditional Policy Permission Presentation

This directory contains a Marp presentation about Red Hat Developer Hub 1.4's conditional policy permission features.

## Contents

- `rhdh-conditional-policy.md` - The main Marp presentation file
- `imgs/` - Directory containing Mermaid diagram files

## How to Use

### Viewing the Presentation

To view the presentation, you need to use a Marp-compatible viewer. You have several options:

1. **VS Code with Marp Extension**:
   - Install the [Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode) extension
   - Open `rhdh-conditional-policy.md` in VS Code
   - Click the "Open Preview to the Side" button or use the keyboard shortcut (Ctrl+K V)

2. **Marp CLI**:
   - Install Marp CLI: `npm install -g @marp-team/marp-cli`
   - Generate HTML: `marp rhdh-conditional-policy.md -o rhdh-conditional-policy.html`
   - Generate PDF: `marp rhdh-conditional-policy.md --pdf`
   - Generate PowerPoint: `marp rhdh-conditional-policy.md --pptx`

### Mermaid Diagrams

The presentation includes Mermaid diagrams stored in the `imgs/` directory. These diagrams are referenced in the presentation using Markdown image links.

To view or edit these diagrams:

1. **VS Code with Mermaid Extension**:
   - Install the [Markdown Preview Mermaid Support](https://marketplace.visualstudio.com/items?itemName=bierner.markdown-mermaid) extension
   - Open any of the `.md` files in the `imgs/` directory
   - Use the Markdown preview to see the rendered diagram

2. **Mermaid Live Editor**:
   - Go to [Mermaid Live Editor](https://mermaid.live/)
   - Copy the Mermaid code from any of the `.md` files (without the triple backticks)
   - Paste it into the editor to view and edit the diagram

## Converting Mermaid to SVG

If you need to convert the Mermaid diagrams to SVG for better compatibility with presentation tools:

```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Convert a Mermaid file to SVG
mmdc -i imgs/permission-workflow.md -o imgs/permission-workflow.svg
mmdc -i imgs/service-account-setup.md -o imgs/service-account-setup.svg
mmdc -i imgs/rhdh-config-process.md -o imgs/rhdh-config-process.svg
mmdc -i imgs/conditional-policy-workflow.md -o imgs/conditional-policy-workflow.svg
```

Then update the image references in `rhdh-conditional-policy.md` to point to the SVG files instead of the MD files.

## Notes

- The presentation is based on the document at `redhat/ocp4/4.16/2025.02.rhdh.condition.permission.md`
- The diagrams illustrate key concepts and workflows related to RHDH's conditional policy permission features
