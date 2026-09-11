import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const DOCUMENTS = ["README.md", "README.es-ES.md", "docs/Usage.md", "docs/Usage.es-ES.md"];
const REMINDER = "README parity required: update the English/Spanish counterpart and run check_readme_parity.";

function editedDocument(event: { toolName: string; input: unknown }): boolean {
	if (event.toolName !== "edit" && event.toolName !== "write") return false;
	const path = String((event.input as { path?: unknown }).path ?? "");
	return DOCUMENTS.some((document) => path === document || path.endsWith(`/${document}`));
}

async function check(pi: ExtensionAPI) {
	const result = await pi.exec("python3", ["scripts/check_readme_parity.py"]);
	return {
		ok: result.code === 0,
		text: (result.stdout || result.stderr || "README parity check failed").trim(),
	};
}

export default function readmeParity(pi: ExtensionAPI) {
	pi.on("tool_result", (event) => {
		if (!event.isError && editedDocument(event)) {
			return { content: [...event.content, { type: "text" as const, text: REMINDER }] };
		}
	});

	pi.registerCommand("readme-parity", {
		description: "Check English/Spanish documentation parity",
		handler: async (_args, ctx) => {
			const result = await check(pi);
			ctx.ui.notify(result.text, result.ok ? "info" : "warning");
		},
	});

	pi.registerTool({
		name: "check_readme_parity",
		label: "Check README parity",
		description: "Check ColorKit English/Spanish documentation for changed-file and structural drift.",
		parameters: Type.Object({}),
		async execute() {
			const result = await check(pi);
			return {
				content: [{ type: "text", text: result.text }],
				details: {},
				isError: !result.ok,
			};
		},
	});
}
