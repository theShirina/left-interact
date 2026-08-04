# Contributing

Thanks for helping improve Left Interact.

## Scope

Keep changes small and compatible with the WotLK 3.3.5a Lua 5.1 environment. Avoid external runtime dependencies unless the benefit clearly outweighs the added install burden.

## Before opening a pull request

1. Describe the client and build you tested.
2. Keep protected binding changes out of combat or defer them until combat ends.
3. Do not edit the permanent `bindings-cache.wtf` files.
4. Preserve Shift + left click and Shift + right click as native fallbacks.
5. Run:

   ```bash
   python -m pip install --require-hashes -r requirements-dev.txt
   python scripts/validate.py
   python scripts/build_release.py
   ```

6. Test the resulting ZIP with a clean extraction into `Interface/AddOns`.

## Reporting bugs

Include:

- Client name and version.
- Movement and interaction mode.
- Exact input sequence.
- Whether the issue happens in combat.
- Any Lua error text.

Do not include account names, credentials, server tokens, or private client files.
