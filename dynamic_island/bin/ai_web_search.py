#!/usr/bin/env python3
import sys
import json
import warnings
warnings.filterwarnings("ignore")
from duckduckgo_search import DDGS

def main():
    if len(sys.argv) < 2:
        return
        
    query = sys.argv[1].strip()
    if not query:
        return
        
    try:
        results = DDGS().text(query, max_results=3)
        context = ""
        for i, r in enumerate(results):
            context += f"Result {i+1}:\nTitle: {r.get('title')}\nContent: {r.get('body')}\nURL: {r.get('href')}\n\n"
        
        if context:
            print(f"WEB SEARCH RESULTS FOR '{query}':\n{context.strip()}")
    except Exception as e:
        # Fail silently to not pollute the context with errors
        pass

if __name__ == "__main__":
    main()
