# Interview Guide

> One rule above all: **Communicate. Don't go silent. Ever.**  
> Interviewer is evaluating how you think, not just what you produce.

---

## What the Interviewer is Actually Evaluating

| Skill | What they're watching |
|---|---|
| **Analytic** | Can you break down an unfamiliar problem? |
| **Coding** | Is your code clean, organized, readable? |
| **Technical** | Do you know the fundamentals? |
| **Communication** | Do you fit the team's culture? |

---

## The 4-Phase Framework

```
Clarification → Think Out Loud → Talk Before Write → Test Your Solution
```

---

## Phase 1 — Clarification

> Never assume. Never start coding immediately. That's a red flag.

**Do this first:**
- Write down the key points of the problem at the top
- Confirm: What are the inputs? What are the outputs?
- Ask: What matters most — time, space, or readability?
- Understand edge cases before you start: nulls? empty arrays? negatives?

**Questions to ask (pick relevant ones):**
```
- What is the expected input size? (small vs massive array changes approach)
- Can inputs be null or undefined?
- Are there duplicate values?
- Is the array sorted?
- What should I return if no answer exists?
- Can I modify the input in place?
```

**Don't:**
- Ask too many questions — read the room
- Ask the same thing twice
- Start coding while clarifying

---

## Phase 2 — Think Out Loud

> Silence is your enemy. Narrate your brain.

**The sequence:**

### Step 1 — State the brute force first
```
"The naive approach here would be a nested loop — O(n²).
For each element I'd scan the rest of the array to find a pair."
```
You don't need to code it. Just say it. It shows structured thinking.

### Step 2 — Identify why it's not good enough
```
"This breaks at large inputs — O(n²) on n=10k is 100M operations.
The bottleneck is the inner scan — I can eliminate that."
```

### Step 3 — Walk toward the optimal
Think out loud about your approach:
```
"If I store what I've seen in a HashMap, I can answer 'have I seen this 
complement before' in O(1) instead of O(n). That brings it to O(n) overall."
```

### Bottleneck Rule
> Find the step with the biggest Big O. That's what you optimize first.  
> Everything else is noise.

Look for:
- Nested loops → can a HashMap eliminate the inner one?
- Repeated work → can you cache/memoize?
- Sorting when not needed → can you avoid it?
- Unused information the interviewer gave you → that's usually a hint

---

## Phase 3 — Talk Before Write

> Write pseudocode / comments FIRST. Code second.

**Before touching code:**
```js
// 1. Build frequency map of all elements — O(n)
// 2. For each element, check if complement exists in map — O(1) per lookup
// 3. Return indices when found
```

**Then convert comments to code:**
```js
function twoSum(nums, target) {
  const map = new Map();               // value → index
  for (let i = 0; i < nums.length; i++) {
    const need = target - nums[i];
    if (map.has(need)) return [map.get(need), i];
    map.set(nums[i], i);
  }
}
```

**Coding discipline:**
- Modularize — break into small named functions
- No single-letter variables (`i`, `j` are ok in loops — but `ptr`, `left`, `right` are better)
- If you can't remember a built-in, write a placeholder function — say you'd look it up
- Start with the easy part if you're stuck on the full solution

**If stuck:**
```
"I'm not sure of the exact syntax here — let me write the logic 
and I can fill in the API details."
```
That's completely acceptable. Shows honesty + problem-solving instinct.

---

## Phase 4 — Test Your Solution

> Never say "I think it works." Prove it.

### Step 1 — Trace through a simple example
```js
// twoSum([2, 7, 11, 15], 9)
// i=0: need=7, map={}, not found. map={2:0}
// i=1: need=2, map has 2! return [0, 1] ✓
```

### Step 2 — Check edge cases
```
□ Empty array []
□ Single element [5]
□ No valid answer exists
□ Duplicates [3, 3] with target 6
□ Negative numbers [-1, 2]
□ Large input (mention it, don't need to run it)
□ null / undefined input
```

### Step 3 — Error handling
```js
// Mention these even if you don't write them:
if (!nums || nums.length < 2) return [];
```

> "I'd add input validation here — check for null, empty array, and 
> non-numeric values before the main logic."

### Step 4 — State complexity
Always close with this:
```
Time: O(n) — single pass, O(1) HashMap lookup
Space: O(n) — HashMap stores up to n elements
```

---

## After the Solution

**Always do this at the end:**
```
"This works. A few things I'd improve:
- Add proper error handling for invalid inputs
- Extract the complement lookup into a helper
- For very large inputs, we might consider streaming — process in chunks"
```

**If interviewer gives hints — take them immediately.**  
That's not cheating. That's communication skills.

---

## Heuristics — What to Reach For

| Situation | Tool |
|---|---|
| Need faster lookup | HashMap / Set |
| Sorted array | Binary Search — O(log n) |
| Optimization needed | Sorting the input first |
| Repeated subproblems | Memoization / DP |
| Need more speed, have memory | Store precomputed state |
| Two-pointer candidate | Sorted array, finding pairs/subarrays |
| Scale / huge input | Divide and conquer, process in chunks |

---

## Good Code Checklist

```
□ It actually works (trace it)
□ Right data structures chosen
□ No repeated logic (DRY)
□ Modular — small functions with clear names
□ No nested loops if avoidable (avoid O(n²))
□ Space complexity considered — no unnecessary copies
□ Edge cases handled or at least mentioned
□ Complexity stated at the end
```

---

## What NOT to Do

| Mistake | Why it hurts |
|---|---|
| Start coding immediately | Shows poor planning |
| Go silent while thinking | Interviewer can't evaluate you |
| Assume inputs are always valid | Breaks in production — they notice |
| "I can't remember the exact method" → give up | Write a placeholder, move on |
| Over-optimize prematurely | Miss the main logic first |
| Single-letter variable names everywhere | Readability matters |
| Never test the code | Looks incomplete |

---

## One-Line Reminders

```
Communicate > Complete
Brute force first, then optimize
HashMap solves most time complexity problems
Sorted array → think Binary Search
Talk about tradeoffs — time vs space
Follow interviewer hints immediately
Close with: complexity + what you'd improve
```