import re

with open('lib/screens/room_ar_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content_lf = content.replace('\r\n', '\n')

# Find the section with SizedBox(height: 24) + recommendation box and insert quick-wins before it
# Use regex to be more flexible with whitespace
pattern = r'([ \t]+)const SizedBox\(height: 24\),\n[ \t]+Container\(\n[ \t]+width: double\.infinity,\n[ \t]+padding: const EdgeInsets\.symmetric\(horizontal: 16, vertical: 14\)'
match = re.search(pattern, content_lf)
if match:
    indent = match.group(1)
    print(f'Found match at pos {match.start()}, indent={repr(indent)}')
    quick_wins = f"""{indent}const SizedBox(height: 16),
{indent}const Align(
{indent}  alignment: Alignment.centerLeft,
{indent}  child: Text('Quick Wins', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
{indent}),
{indent}const SizedBox(height: 8),
{indent}SizedBox(height: 82, child: ListView(
{indent}  scrollDirection: Axis.horizontal,
{indent}  children: [
{indent}    _quickWinCard('TV Standby', 'Unplug!', '\u20b9630/yr', Colors.orangeAccent),
{indent}    _quickWinCard('Curtains', 'Blackout', '\u20b91,200/yr', Colors.purpleAccent),
{indent}    _quickWinCard('Lighting', 'Switch LEDs', '\u20b92,400/yr', Colors.yellowAccent),
{indent}    _quickWinCard('AC', 'Set 24\u00b0C', '\u20b93,600/yr', Colors.cyanAccent),
{indent}  ],
{indent})),
{indent}const SizedBox(height: 14),
"""
    content_lf = content_lf[:match.start()] + quick_wins + content_lf[match.start():]
    print('SUCCESS: quick wins inserted')
else:
    print('Match not found, dump first 3000 chars:')
    print(content_lf[:3000])
    exit(1)

# Add _quickWinCard helper before Widget _dashStat
helper = """
  Widget _quickWinCard(String title, String action, String saving, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
              Text(saving, style: const TextStyle(color: Colors.white38, fontSize: 8)),
            ]),
            const SizedBox(height: 6),
            Text(action, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _dashStat("""

if '  Widget _dashStat(' in content_lf:
    content_lf = content_lf.replace('  Widget _dashStat(', helper, 1)
    print('SUCCESS: _quickWinCard helper added')
else:
    print('WARNING: _dashStat not found')

with open('lib/screens/room_ar_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content_lf)
print('File written.')
