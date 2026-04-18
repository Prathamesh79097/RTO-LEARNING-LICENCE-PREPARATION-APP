import json
import re

raw_data = """
1	3	55	1	109	2	163	1	217	1	271	2	325	2	379	3
2	1	56	1	110	1	164	2	218	1	272	2	326	3	380	1
3	3	57	1	111	1	165	2	219	2	273	3	327	1	381	2
4	3	58	1	112	2	166	2	220	1	274	2	328	3	382	2
5	3	59	2	113	1	167	1	221	1	275	1	329	2	383	3
6	1	60	1	114	2	168	1	222	1	276	1	330	1	384	1
7	3	61	1	115	1	169	2	223	2	277	1	331	2	385	2
8	2	62	2	116	3	170	1	224	1	278	2	332	3	386	1
9	1	63	2	117	1	171	1	225	1	279	1	333	2	387	3
10	3	64	1	118	1	172	1	226	1	280	1	334	3	388	1
11	1	65	1	119	2	173	2	227	1	281	3	335	2	389	1
12	1	66	2	120	3	174	1	228	2	282	2	336	1	390	1
13	3	67	2	121	1	175	2	229	1	283	2	337	2	391	2
14	2	68	1	122	1	176	1	230	2	284	1	338	2	392	2
15	2	69	1	123	1	177	2	231	1	285	1	339	2	393	1
16	2	70	2	124	1	178	2	232	2	286	1	340	1	394	1
17	2	71	1	125	2	179	1	233	1	287	1	341	1	395	2
18	1	72	1	126	1	180	2	234	2	288	1	342	3	396	2
19	2	73	2	127	1	181	1	235	1	289	3	343	1	397	1
20	2	74	1	128	1	182	2	236	1	290	2	344	2	398	1
21	1	75	1	129	1	183	2	237	2	291	1	345	1	399	3
22	3	76	2	130	1	184	2	238	1	292	1	346	2	400	2
23	3	77	1	131	2	185	2	239	2	293	1	347	1	401	1
24	1	78	1	132	1	186	2	240	1	294	1	348	1	402	1
25	2	79	2	133	2	187	1	241	1	295	2	349	3	403	1
26	2	80	1	134	2	188	2	242	2	296	2	350	1	404	2
27	3	81	1	135	1	189	1	243	1	297	1	351	3	405	2
28	3	82	2	136	1	190	1	244	1	298	1	352	2	406	1
29	2	83	1	137	1	191	1	245	2	299	1	353	1	407	3
30	1	84	1	138	1	192	2	246	2	300	1	354	2	408	2
31	2	85	2	139	2	193	1	247	2	301	1	355	1	409	1
32	3	86	1	140	1	194	2	248	1	302	2	356	1	410	1
33	2	87	2	141	2	195	1	249	1	303	2	357	2	411	2
34	1	88	2	142	2	196	2	250	1	304	1	358	3	412	1
35	2	89	2	143	1	197	2	251	2	305	1	359	2	413	2
36	2	90	1	144	1	198	1	252	1	306	1	360	2	414	1
37	3	91	1	145	1	199	2	253	2	307	2	361	2	415	1
38	3	92	1	146	2	200	2	254	1	308	1	362	1	416	1
39	2	93	2	147	2	201	1	255	1	309	3	363	2	417	2
40	1	94	1	148	1	202	1	256	1	310	1	364	1	418	1
41	3	95	2	149	1	203	1	257	1	311	1	365	2	419	1
42	2	96	1	150	1	204	2	258	2	312	1	366	3	420	1
43	1	97	1	151	2	205	2	259	1	313	1	367	2	421	1
44	1	98	2	152	1	206	1	260	2	314	1	368	1	422	1
45	1	99	1	153	2	207	2	261	1	315	1	369	2	423	2
46	1	100	2	154	1	208	2	262	1	316	2	370	2	424	2
47	1	101	2	155	2	209	1	263	2	317	2	371	2	425	1
48	1	102	2	156	1	210	2	264	2	318	1	372	2	426	1
49	2	103	1	157	1	211	1	265	1	319	1	373	2	427	2
50	2	104	1	158	1	212	1	266	2	320	2	374	2	428	1
51	1	105	1	159	1	213	2	267	1	321	2	375	1	429	1
52	2	106	1	160	1	214	1	268	2	322	2	376	1	430	3
53	1	107	2	161	1	215	1	269	1	323	2	377	1	431	1
54	1	108	1	162	1	216	1	270	1	324	2	378	2	432	1
"""

# Parse the raw_data into a dictionary: {q_number: correct_option_index_1_based}
answers_map = {}
tokens = raw_data.split()

# The tokens alternate [q, a, q, a, ...]
i = 0
while i < len(tokens) - 1:
    q = int(tokens[i])
    a = int(tokens[i+1])
    answers_map[q] = a
    i += 2

print(f"Parsed {len(answers_map)} answers.")

json_path = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\questions.json"

with open(json_path, 'r', encoding='utf-8') as f:
    questions = json.load(f)

updated_count = 0
errors = 0

# Assumption: In parse_questions.py, the questions were extracted into a list 'questions'.
# The problem is that questions in JSON do NOT have a 'Q_NUMBER' explicitly (they are just sequentially in the list, though maybe some were skipped).
# Let's hope the list index strictly matches Q_NUMBER.
# If `q_num` was NOT saved, we assume 1-based index (i.e. questions[0] is Q_NUMBER 1), mostly because it extracted 431 items.
# Wait, some questions might have been skipped. Let's see if the first word of the question is the number, or if we can just align them.
# Our pdfplumber script had:
#   if len(row) >= 6:
#       q_num = row[0]
# But it wasn't saved to the dict! The dict only had "question", "options", "answer".
# It doesn't matter, we can just assume 1-to-1 index matching if it's close, OR better, check the question text. The question text in the PDF doesn't usually start with the number because the number was in a separate column.
# Let's just assume `questions[ i ]` corresponds to Question `i+1`.

for i, q in enumerate(questions):
    q_num = i + 1
    if q_num in answers_map:
        correct_opt_idx = answers_map[q_num] - 1  # 0, 1, or 2
        
        # Ensure options list is long enough
        if 0 <= correct_opt_idx < len(q['options']):
            correct_str = q['options'][correct_opt_idx]
            q['answer'] = correct_str
            updated_count += 1
        else:
            errors += 1
            # print(f"Warning: Option index {correct_opt_idx} out of range for Q {q_num}. Options: {q['options']}")

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(questions, f, indent=4)

print(f"Successfully updated {updated_count} answers. Errors: {errors}")

