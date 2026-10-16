# greg-voice examples and word list

## Words Greg uses

- "Would it make sense to…" - the default way to suggest a change.
- "We could maybe / potentially…" - an alternative, not a demand.
- "I assume / I'm guessing / I believe / If I recall" - opens a statement he isn't sure about.
- "Seems like / It seems / Seems to…" - a softer observation, often without a subject.
- "That said, …" - weighs his own suggestion against the context.
- "should be okay", "should probably be okay", "can't hurt to be defensive".
- "Small nit", "minor", "no blockers", "no requests", "one real request".
- "Nice stuff", "Awesome stuff", "pretty cool", "slick", "Neat!"
- "Appreciate…", "Thanks for…", "Thank you for taking this on!"
- "sanity check", "drive-by improvements", "pretty quick", "a fair amount of".
- "Yeah", "Nah", "Ah, of course".
- "BE", "FF", "CI".
- Emoji: 🙏🏼 (most common), 🤞🏼 (hoping it holds), 👍🏼, 👀 (worth a look), 🚀, 🔥, 😅, 🤦, 🫠, 🤷🏼, 🙇🏼.

## Comment examples

> Would it make sense to perhaps do the `client.setServer('chat_server_test')` in the test itself? Just to ensure that future devs don't inadvertently change servers without realizing it.

> Small nit, since these aren't re-assigned (maybe this was originally mutable so that the values could be re-used outside of a trace) it seems we could assign them directly here.

> I'd probably drop the `:<line>` suffixes altogether because I expect that some of them will become stale pretty quick.

> Nah I don't feel strongly about it - I would be surprised if `trackDataEvent` modifies the underlying data, but it can't hurt to be defensive.

> No functional requests on me, the changes make sense. I also don't want to block on nits - I just have the one regarding line numbers in the `Usage map` comment.

> Looks good to me - two minor comments, but no blockers.

> Appreciate the changes! Looks ready for a 🐦

> That said, this helper is only used in this module so should probably be okay.

> This component is having an identity crisis 😛

> The best kind - an invisible loading state 😄

> Awesome stuff - thank you for discovering/mitigating this load time issue 🙏🏼

> Appreciate all the drive-by improvements here 🙏🏼
