@preprocessor typescript


@{%
		function join(sequence: string[]) {
			// console.log('join', sequence)
			if (sequence.length == 1) {
					return sequence[0];
			}
			let memo = '';
			for (const item of sequence) {
					memo = memo + item;
			}
			return memo;
		}

		const stringOfSame = ([tokens]: string[][]) => tokens.join('');
		const stringAppendAfterGap = ([first, gap, next]: string[]) => first + gap + next;
		const pair = ([first, next]: string[]) => [first, next];
		const token = ([tok]: string[]) => tok;
		const symbolToSegmentKey = (symbol: string) => {
			switch (symbol){
						case '|': return 'projectSegment';
						case '@': return 'organizationSegment';
						case ':': return 'versionSegment';
					}
			}
%}

branchLocator
	-> head tail:? {%
		([head, tail]) => {
		  return {
			...head,
			...tail,
		  }
		}
	%}

head
 	-> (segmentGroup | "-") "::" head {%
		([[namespaceSegment], mark, pathObject]) => {
			if (namespaceSegment === '-') return pathObject;
		  return {
			namespaceSegment,
			...pathObject,
		  }
		}
	%}
	| (segmentGroup | "-") {% ([[pathSegment]]) => {
		if (pathSegment === '-') return {}
		return {pathSegment}
		} %}

tail
	-> markedSegment:+ {%
		([segments]: string[][][]) => {
		  const locator: any = {};
		  for (const [key, value] of segments) {
				if (value){
					const existing = locator[key];
					if (existing){
						const set = locator[key + 's'];
						locator[key + 's'] = [...(set || [existing]), value];
					} else {
						locator[key] = value;
					}
				}
		  }
		  return locator;
		}
	%}

markedSegment
  -> [@|:] segmentGroup {% ([mark, value]) => {
		return [symbolToSegmentKey(mark), value];
		} %}
	| [@|:] "-" {% ([mark, value]) => {
		return [symbolToSegmentKey(mark), null];
	} %}

segmentGroup
 	-> chunk gap segmentGroup {% stringAppendAfterGap %}
	| chunk {% id %}

chunk
	-> number word number {% join %}
	| word number {% join %}
	| number word {% join %}
	| word {% join %}
	| number {% join %}

gap
  -> __ {% id %}
  | [/] {% token %}

number
	-> number numeric {% join %}
	| numeric {% id %}

numeric
	-> [0-9] {% token %}


word
	-> alpha {% id %}
	| alpha alphaSeparator word {% join %}

alphaSeparator
  -> [-] {% token %}

alpha
	-> [a-zA-Z]:+ {% stringOfSame %}

__
	-> " ":+ {% ([tokens]) => {
				let spaces = '';
				for (const i of tokens){
					spaces += ' ';
				}
				return spaces;
			} %}
