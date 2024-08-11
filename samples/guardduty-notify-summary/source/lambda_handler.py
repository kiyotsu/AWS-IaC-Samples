import os
import boto3
import json

BEDROCK_MODEL_ID = "anthropic.claude-3-5-sonnet-20240620-v1:0"
BEDROCK_MAX_TOKENS = 1000
SNS_TOPIC = os.environ['SNS_TOPIC']

bedrock = boto3.client("bedrock-runtime")
sns = boto3.client('sns')


def generate_message(guardduty_result):
    prompt = f"""
    Please provide an overview of GuardDuty detection results and countermeasures in Japanese.
    result: {guardduty_result}

    Please follow the format:
    [Overview]
    Summary of GuardDuty findings
    [Datetime]
    The format is 'yyyy-mm-dd HH:MM:SS'.
    The time is local time.
    [Content]
    GuardDuty finding details
    [Countermeasure instructions]
    Countermeasures for detection results
    """

    request = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": BEDROCK_MAX_TOKENS,
        "messages": [
            {
                "role": "user",
                "content": prompt,
            }
        ],
    })

    response = bedrock.invoke_model(modelId=BEDROCK_MODEL_ID, body=request)
    response_body = json.loads(response.get('body').read())

    return response_body["content"][0]["text"]


def lambda_handler(event, context):

    try:
        # Summarize GuardDuty findings
        message = generate_message(event)

        # Notify summary
        sns.publish(
            TopicArn=SNS_TOPIC,
            Message=message,
            Subject=f'[{event["account"]}] GuardDuty notify summary'
        )
    except Exception as e:
        print(e)
