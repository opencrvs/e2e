import { editor } from '@inquirer/prompts';
import { findExistingValue } from './utils';
import { Secret, Variable } from './github';
import { AnswerWithNullValue, Answers, QuestionDescriptor } from './custom-types';
import kleur from 'kleur'
import prompts from 'prompts'


export function editorQuestion(question: string): Promise<string> {
    return editor({
        message: question
    })
}

export async function askQuestionWithEditor(
    questions: Array<QuestionDescriptor<any>>,
    existingValues: Array<Secret | Variable>
): Promise<AnswerWithNullValue[]> {
    let answers: AnswerWithNullValue[] = [];
    for (const question of questions) {
        const questionWithVariableLabel = {
            ...question,
            message: `${kleur.cyan(question.valueLabel || '')}: ${question.message}`
        }
        if (!questionWithVariableLabel.valueLabel) {
            throw Error("Undefined Label")
        }
        const existingSecret = findExistingValue(
            questionWithVariableLabel.valueLabel,
            'SECRET',
            questionWithVariableLabel.scope,
            existingValues
        )
        let updateSecret = true;
        if (existingSecret) {
            updateSecret = (await prompts([{
                name: 'overWrite',
                type: 'confirm' as const,
                message: `${kleur.yellow(
                    `${existingSecret.scope === 'REPOSITORY'
                        ? 'Repository secret'
                        : 'Secret'
                    } ${kleur.cyan(
                        existingSecret.name
                    )} already exists in Github. Do you want to update it?`
                )}`
            }])).overWrite
        }

        if (!existingSecret || updateSecret === true) {
            const question_answer = await editorQuestion(questionWithVariableLabel.message);
            const answer: AnswerWithNullValue = {
                type: 'SECRET',
                scope: 'ENVIRONMENT',
                name: questionWithVariableLabel.valueLabel,
                value: question_answer,
                didExist: existingSecret
            }
            answers.push(answer);
        }
    }
    return answers;
}