# Author: Thomas Young
# Modified by Juwon Seo (knowin-kyeong)

import numpy, random
from concurrent.futures import ProcessPoolExecutor  # For Parallel training

from agent import TetrisAI

f = open("Data.txt", "w+")

agentID = 1


class Generation(object):
    def __init__(self, num_gen_instances, mutation_val=0.05, alive_rate=0.25, iter_generation=10):
        self.num_gen_instances = num_gen_instances
        self.mutation_val = mutation_val
        self.alive_rate = alive_rate

        self.generation = 1
        self.iter_generation = iter_generation

        self.agents = []
        self.results = None

        global agentID
        for i in range(num_gen_instances):
            self.agents.append(TetrisAI(str(agentID) + "th Element"))
            agentID += 1

            self.agents[i].set_init_weights()

    '''
    Saves data from previous generation, preforms selection, crossover, and mutation
    '''

    def play_agent(self, agent, idx):
        result = agent.play_game()
        print("Score for agent idx {} : {}".format(idx, result['play_score']))
        return {
            "weights": result['weights'],
            "play_score": result['play_score'],
            "agent_idx": idx
        }

    def play_gen(self):
        if self.generation <= self.iter_generation:
            print("{}th Generation is started".format(self.generation))
        else:
            print("Collecting the results...")

        with ProcessPoolExecutor() as executor:
            futures = [executor.submit(self.play_agent, agent, idx) for idx, agent in enumerate(self.agents)]
            results = [future.result() for future in futures]

        self.results = results

    def generation_update(self):
        self.results = sorted(self.results, key=lambda x: x['play_score'], reverse=True)

        gen_score = sum(result['play_score'] for result in self.results) / self.num_gen_instances
        f.write("Generation {} score: {}\n".format(self.generation, gen_score))
        print("Generation Score: \n", gen_score)

        top_results = self.results[0:int(self.num_gen_instances * self.alive_rate)]
        new_weights = [list(result['weights'].values()) for result in top_results]

        # crossover
        initial_new_weights = new_weights
        cnt = 0
        prev_comb = []
        while cnt < (self.num_gen_instances - len(initial_new_weights)) // 2:
            idx_1 = random.randint(0, len(initial_new_weights) - 1)
            idx_2 = random.randint(0, len(initial_new_weights) - 1)
            if idx_1 > idx_2:
                idx_1, idx_2 = idx_2, idx_1

            if idx_1 == idx_2:
                continue
            elif (idx_1, idx_2) in prev_comb:
                continue
            else:
                prev_comb.append((idx_1, idx_2))
                cnt += 1

        for i, j in prev_comb:
            gen1 = initial_new_weights[i]
            gen2 = initial_new_weights[j]

            new_gen1, new_gen2 = self.mix_genes(gen1, gen2)

            new_weights.append(new_gen1)
            new_weights.append(new_gen2)

        # mutation
        for idx in range(len(new_weights)):
            new_weights[idx] = self.mutate_gene(new_weights[idx])

        print("{}th Generation is finished. Updating...".format(self.generation))

        self.generation += 1

        self.agents = []
        self.results = None

        global agentID
        agentID = 1
        for i in range(self.num_gen_instances):
            self.agents.append(TetrisAI(str(agentID) + "th Element"))
            agentID += 1

            self.agents[i].load_weights(new_weights[i])

    def mix_genes(self, gene1, gene2):
        if len(gene1) != len(gene2):
            raise ValueError('A very specific bad thing happened.')

        num_features = len(self.agents[0].features)
        switch_idx = numpy.random.choice(range(num_features), num_features // 2, replace=False)

        new_gene1 = [0 for _ in range(len(gene1))]
        new_gene2 = [0 for _ in range(len(gene2))]

        for idx in range(len(gene1)):
            if idx in switch_idx:
                new_gene1[idx] = gene2[idx]
                new_gene2[idx] = gene1[idx]
            else:
                new_gene1[idx] = gene1[idx]
                new_gene2[idx] = gene2[idx]

        return new_gene1, new_gene2

    def mutate_gene(self, gene):
        num_features = len(self.agents[0].features)

        # try for mutation with 5% change of success
        if random.randint(0, 100) > 5:
            return gene

        mutate_idx = numpy.random.choice(range(num_features), random.randint(0, num_features), replace=False)

        new_gene = [0 for _ in range(len(gene))]

        for idx in range(len(gene)):
            mut_val = 0
            if idx in mutate_idx:
                mut_val = random.uniform(-self.mutation_val, self.mutation_val)
            new_gene[idx] = gene[idx] + mut_val

        return new_gene

    def train_gene(self):
        for _ in range(self.iter_generation):
            self.play_gen()
            self.generation_update()

        self.play_gen()
        return self.results


if __name__ == "__main__":
    genetic_module = Generation(num_gen_instances=32)
    results = genetic_module.train_gene()
    print(results)
