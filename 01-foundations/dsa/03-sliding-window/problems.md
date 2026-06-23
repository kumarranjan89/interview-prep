# Sliding Window — Problems

NeetCode 150 — Sliding Window section.  
Solve yourself first. Look only after 20 min.

---

## Problem 1 — Best Time to Buy and Sell Stock

**Link:** https://leetcode.com/problems/best-time-to-buy-and-sell-stock/

**Problem:**  
Given prices array, find max profit from one buy and one sell.  
Must buy before sell.

```
Input:  [7,1,5,3,6,4]
Output: 5  → buy at 1, sell at 6

Input:  [7,6,4,3,1]
Output: 0  → no profit possible
```

**Pattern:** Sliding window — track min price (left), max profit.

**Approach:**
- left = buy day, right = sell day
- If prices[right] < prices[left] → new cheaper buy found → left = right
- Else → calculate profit, update max
- Move right forward each step

**Dry Run:**
```
prices = [7,1,5,3,6,4]
L=0, R=1, maxProfit=0

R=1: prices[1]=1 < prices[0]=7 → L=1
R=2: prices[2]=5 > prices[1]=1 → profit=5-1=4, max=4
R=3: prices[3]=3 > prices[1]=1 → profit=3-1=2, max=4
R=4: prices[4]=6 > prices[1]=1 → profit=6-1=5, max=5
R=5: prices[5]=4 > prices[1]=1 → profit=4-1=3, max=5

return 5 ✅
```

**Solution:**
```js
function maxProfit(prices) {
  let left = 0;
  let maxProfit = 0;

  for (let right = 1; right < prices.length; right++) {
    if (prices[right] < prices[left]) {
      left = right;
    } else {
      maxProfit = Math.max(maxProfit, prices[right] - prices[left]);
    }
  }

  return maxProfit;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) |

**Edge Cases:**
- Strictly decreasing → 0
- Single element → 0
- All same → 0

---

## Problem 2 — Longest Substring Without Repeating Characters

**Link:** https://leetcode.com/problems/longest-substring-without-repeating-characters/

**Problem:**  
Find length of longest substring with all unique characters.

```
Input:  "abcabcbb"
Output: 3  → "abc"

Input:  "bbbbb"
Output: 1  → "b"
```

**Pattern:** Variable window + Hash Set to track characters in window.

**Approach:**
- Expand right — add character to set
- If duplicate found — shrink left until duplicate removed
- Track max window size

**Dry Run:**
```
s = "abcabcbb"
set={}, L=0, max=0

R=0 'a' → set={a}, max=1
R=1 'b' → set={a,b}, max=2
R=2 'c' → set={a,b,c}, max=3
R=3 'a' → 'a' in set → remove s[L]='a', L++ → set={b,c}, L=1
           'a' not in set → set={b,c,a}, max=3
R=4 'b' → 'b' in set → remove s[L]='b', L++ → set={c,a}, L=2
           'b' not in set → set={c,a,b}, max=3
R=5 'c' → 'c' in set → remove s[L]='c', L++ → set={a,b}, L=3
           'c' not in set → set={a,b,c}, max=3
R=6 'b' → 'b' in set → shrink → max=3
R=7 'b' → 'b' in set → shrink → max=3

return 3 ✅
```

**Solution:**
```js
function lengthOfLongestSubstring(s) {
  const set = new Set();
  let left = 0;
  let max = 0;

  for (let right = 0; right < s.length; right++) {
    while (set.has(s[right])) {
      set.delete(s[left]);
      left++;
    }
    set.add(s[right]);
    max = Math.max(max, right - left + 1);
  }

  return max;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(min(n, 26)) — charset size |

**Edge Cases:**
- Empty string → 0
- All unique → length of string
- All same → 1

---

## Problem 3 — Longest Repeating Character Replacement

**Link:** https://leetcode.com/problems/longest-repeating-character-replacement/

**Problem:**  
Given string and k (max replacements), find longest substring with same character after at most k replacements.

```
Input:  s = "AABABBA", k = 1
Output: 4  → "AABA" or "ABBA"
```

**Pattern:** Variable window + frequency map.

**Key Insight:**  
Window is valid when: `windowSize - maxFreqChar <= k`  
(replacements needed = window size - count of most frequent char)

**Approach:**
- Expand right, update frequency map
- If window invalid → shrink left
- Track max window

**Dry Run:**
```
s = "AABABBA", k=1
count={}, L=0, maxFreq=0, max=0

R=0 'A': count={A:1}, maxFreq=1, window=1, 1-1=0<=1 valid, max=1
R=1 'A': count={A:2}, maxFreq=2, window=2, 2-2=0<=1 valid, max=2
R=2 'B': count={A:2,B:1}, maxFreq=2, window=3, 3-2=1<=1 valid, max=3
R=3 'A': count={A:3,B:1}, maxFreq=3, window=4, 4-3=1<=1 valid, max=4
R=4 'B': count={A:3,B:2}, maxFreq=3, window=5, 5-3=2>1 invalid
         shrink: remove s[0]='A' → count={A:2,B:2}, L=1, window=4, 4-3=1<=1 valid
R=5 'B': count={A:2,B:3}, maxFreq=3, window=5, 5-3=2>1 invalid
         shrink: remove s[1]='A' → count={A:1,B:3}, L=2, window=4 valid, max=4
R=6 'A': count={A:2,B:3}, maxFreq=3, window=5, 5-3=2>1 invalid
         shrink: remove s[2]='B' → count={A:2,B:2}, L=3, window=4 valid, max=4

return 4 ✅
```

**Solution:**
```js
function characterReplacement(s, k) {
  const count = new Map();
  let left = 0;
  let maxFreq = 0;
  let max = 0;

  for (let right = 0; right < s.length; right++) {
    count.set(s[right], (count.get(s[right]) || 0) + 1);
    maxFreq = Math.max(maxFreq, count.get(s[right]));

    while ((right - left + 1) - maxFreq > k) {
      count.set(s[left], count.get(s[left]) - 1);
      left++;
    }

    max = Math.max(max, right - left + 1);
  }

  return max;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(26) = O(1) |

**Edge Cases:**
- k >= string length → return string length
- All same chars → return string length
- k = 0 → longest run of same char

---

## Problem 4 — Permutation in String

**Link:** https://leetcode.com/problems/permutation-in-string/

**Problem:**  
Return true if s2 contains a permutation of s1 as a substring.

```
Input:  s1 = "ab", s2 = "eidbaooo"
Output: true  → "ba" is permutation of "ab"
```

**Pattern:** Fixed window (size = s1.length) + frequency map comparison.

**Approach:**
- Count frequency of s1 characters
- Slide window of size s1.length over s2
- At each position, compare window frequency with s1 frequency
- Match → return true

**Dry Run:**
```
s1="ab", s2="eidbaooo"
need={a:1, b:1}, window size=2

window "ei": {e:1,i:1} ≠ need
window "id": {i:1,d:1} ≠ need
window "db": {d:1,b:1} ≠ need
window "ba": {b:1,a:1} = need → return true ✅
```

**Solution:**
```js
function checkInclusion(s1, s2) {
  if (s1.length > s2.length) return false;

  const need = new Array(26).fill(0);
  const window = new Array(26).fill(0);
  const a = 'a'.charCodeAt(0);

  for (const c of s1) need[c.charCodeAt(0) - a]++;

  for (let i = 0; i < s2.length; i++) {
    window[s2[i].charCodeAt(0) - a]++;

    // remove leftmost char when window exceeds s1 size
    if (i >= s1.length) {
      window[s2[i - s1.length].charCodeAt(0) - a]--;
    }

    if (need.join('') === window.join('')) return true;
  }

  return false;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(1) — fixed 26 size arrays |

**Edge Cases:**
- s1 longer than s2 → false
- s1 === s2 → true
- s1 length 1 → check if char exists in s2

---

## Problem 5 — Minimum Window Substring

**Link:** https://leetcode.com/problems/minimum-window-substring/

**Problem:**  
Find minimum window in s that contains all characters of t.

```
Input:  s = "ADOBECODEBANC", t = "ABC"
Output: "BANC"
```

**Pattern:** Variable window + frequency map + match counter.

**Approach:**
- Count t characters needed
- Expand right — when a needed char found, increment matches
- When all matched → try shrink left → update min window
- Shrink until window invalid, then expand again

**Dry Run:**
```
s="ADOBECODEBANC", t="ABC"
need={A:1,B:1,C:1}, required=3, matches=0

Expand until matches=3:
A→matches=1, D, O, B→matches=2, E, C→matches=3
Window: "ADOBEC", len=6, minWindow="ADOBEC"

Shrink left:
remove A → matches=2, expand again
...
Eventually window="BANC", len=4 → minWindow="BANC" ✅
```

**Solution:**
```js
function minWindow(s, t) {
  if (!t.length) return "";

  const need = new Map();
  for (const c of t) need.set(c, (need.get(c) || 0) + 1);

  let left = 0;
  let matches = 0;
  const required = need.size;
  let minLen = Infinity;
  let minStart = 0;

  for (let right = 0; right < s.length; right++) {
    const c = s[right];
    if (need.has(c)) {
      need.set(c, need.get(c) - 1);
      if (need.get(c) === 0) matches++;
    }

    while (matches === required) {
      if (right - left + 1 < minLen) {
        minLen = right - left + 1;
        minStart = left;
      }
      const lc = s[left];
      if (need.has(lc)) {
        need.set(lc, need.get(lc) + 1);
        if (need.get(lc) > 0) matches--;
      }
      left++;
    }
  }

  return minLen === Infinity ? "" : s.slice(minStart, minStart + minLen);
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(t) |

**Edge Cases:**
- t not in s → ""
- s === t → s
- Duplicate chars in t → handle with count

---

## Problem 6 — Sliding Window Maximum

**Link:** https://leetcode.com/problems/sliding-window-maximum/

**Problem:**  
Return max of each window of size k.

```
Input:  nums=[1,3,-1,-3,5,3,6,7], k=3
Output: [3,3,5,5,6,7]
```

**Pattern:** Fixed window + Monotonic Deque (decreasing).

**Approach:**
- Deque stores indices, front = max of current window
- Add right: remove all smaller elements from back (they'll never be max)
- Remove left: if front index out of window, remove it
- After first window built, add front to result each step

**Dry Run:**
```
nums=[1,3,-1,-3,5,3,6,7], k=3
deque=[], result=[]

i=0: num=1, deque=[0]
i=1: num=3 > nums[0]=1 → pop 0, deque=[1]
i=2: num=-1 < nums[1]=3 → deque=[1,2]
     window complete → result=[nums[1]]=[3]

i=3: num=-3 < nums[2]=-1 → deque=[1,2,3]
     front=1, still in window [1,3] → result=[3, nums[1]]=[3,3]

i=4: num=5 > all → pop 3,2,1 → deque=[4]
     result=[3,3,5]

i=5: num=3 < nums[4]=5 → deque=[4,5]
     result=[3,3,5,5]

i=6: num=6 > nums[5]=3 → pop 5, 6>nums[4]=5 → pop 4, deque=[6]
     result=[3,3,5,5,6]

i=7: num=7 > nums[6]=6 → pop 6, deque=[7]
     result=[3,3,5,5,6,7] ✅
```

**Solution:**
```js
function maxSlidingWindow(nums, k) {
  const deque = []; // stores indices
  const result = [];

  for (let i = 0; i < nums.length; i++) {
    // remove out-of-window index from front
    if (deque.length && deque[0] < i - k + 1) deque.shift();

    // remove smaller elements from back
    while (deque.length && nums[deque[deque.length - 1]] < nums[i]) {
      deque.pop();
    }

    deque.push(i);

    // start adding results after first window
    if (i >= k - 1) result.push(nums[deque[0]]);
  }

  return result;
}
```

**Complexity:**
| | |
|--|--|
| Time | O(n) |
| Space | O(k) |

**Edge Cases:**
- k = 1 → return nums
- k = nums.length → return [max]
- All same → each window returns same value

---

## Summary

| # | Problem | Pattern | Time | Space |
|---|---------|---------|------|-------|
| 1 | Best Time to Buy/Sell Stock | Variable window | O(n) | O(1) |
| 2 | Longest Substring No Repeat | Variable + Set | O(n) | O(n) |
| 3 | Longest Repeating Replacement | Variable + freq map | O(n) | O(1) |
| 4 | Permutation in String | Fixed + freq map | O(n) | O(1) |
| 5 | Minimum Window Substring | Variable + freq map | O(n) | O(t) |
| 6 | Sliding Window Maximum | Fixed + Deque | O(n) | O(k) |